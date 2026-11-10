/// Shared manual redirect machinery for trusted-host downloads.
///
/// Dio is not allowed to follow a redirect it cannot re-validate: a
/// compromised host must not steer bytes to an `http://` or foreign
/// destination. Both downloaders (library packs and recitation audio) used
/// to carry hand-copied versions of this file's three primitives; they now
/// share one implementation so a hardening fix cannot drift.
library;

import 'package:dio/dio.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

/// The 3xx codes worth following. Anything else is terminal (2xx streams as
/// before; other statuses fail like Dio would).
const Set<int> kRedirectStatuses = {301, 302, 303, 307, 308};

/// 2xx or a followable 3xx — collapse nothing, so the hop guard sees every
/// 3xx instead of Dio throwing before its Location can be inspected.
bool acceptSuccessOrRedirect(int? status) =>
    status != null &&
    ((status >= 200 && status < 300) || kRedirectStatuses.contains(status));

/// Releases a redirect response body so its socket is not left half-read.
/// Best-effort by design: a broken body cannot change a verdict, so it is
/// only logged.
Future<void> discardRedirectBody(
  ResponseBody? body, {
  required String devLogName,
}) async {
  if (body == null) return;
  try {
    await body.stream.drain<void>();
  } on Object catch (error, stackTrace) {
    appLog(
      'discard redirect body failed',
      name: devLogName,
      error: error.runtimeType,
      stackTrace: stackTrace,
    );
  }
}

/// Follows up to [maxHops] redirects from [start], streaming each response.
///
/// The caller re-validates every hop-by-hop Location inside [resolveNext]
/// (scheme, host allowlist) and throws its own typed failure there — the
/// throw propagates unchanged. [failure] produces the caller's typed
/// exception for the two guard verdicts that belong to the loop itself:
/// a redirect without a usable Location header, and exceeding [maxHops].
///
/// [headers] are re-sent on every hop on purpose (a redirect must not turn a
/// resume into a full download).
Future<Response<ResponseBody>> followTrustedRedirects({
  required Dio dio,
  required Uri start,
  required int maxHops,
  required String devLogName,
  required Uri Function(Uri current, String location) resolveNext,
  required Object Function(String message) failure,
  CancelToken? cancelToken,
  Map<String, Object>? headers,
}) async {
  var current = start;
  for (var hop = 0; hop <= maxHops; hop++) {
    final res = await dio.get<ResponseBody>(
      current.toString(),
      options: Options(
        responseType: ResponseType.stream,
        // Dio must hand every 3xx back instead of following it itself.
        followRedirects: false,
        validateStatus: acceptSuccessOrRedirect,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );
    final status = res.statusCode ?? 0;
    if (!kRedirectStatuses.contains(status)) return res;
    final location = res.headers.value('location')?.trim();
    await discardRedirectBody(res.data, devLogName: devLogName);
    if (location == null || location.isEmpty) {
      throw failure('redirect $status is missing a Location header');
    }
    current = resolveNext(current, location);
  }
  throw failure('redirect chain exceeded $maxHops hops');
}
