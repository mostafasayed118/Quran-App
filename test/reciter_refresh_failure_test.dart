import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

/// A Dio adapter that answers every request from [onFetch].
class _FailingAdapter implements HttpClientAdapter {
  _FailingAdapter(this.onFetch);

  final Future<ResponseBody> Function(RequestOptions options) onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      onFetch(options);

  @override
  void close({bool force = false}) {}
}

ReciterRepository _repo(AppDatabase db, HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ReciterRepository(
    db,
    client: dio,
    apiEndpointOverride: 'https://catalog.example.test/reciters',
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  tearDown(() async => db.close());

  test('a timeout is surfaced and leaves the catalog untouched', () async {
    final repo = _repo(
      db,
      _FailingAdapter((_) async => throw TimeoutException('catalog timeout')),
    );

    await expectLater(repo.refreshFromApi(), throwsA(isA<TimeoutException>()));
    expect(await db.select(db.reciters).get(), isEmpty);
  });

  test('a 5xx response is surfaced and leaves the catalog untouched', () async {
    final repo = _repo(
      db,
      _FailingAdapter(
        (_) async => ResponseBody.fromString('', 503),
      ),
    );

    await expectLater(repo.refreshFromApi(), throwsA(isA<StateError>()));
    expect(await db.select(db.reciters).get(), isEmpty);
  });

  test('a connection failure is surfaced, never a partial rewrite', () async {
    final repo = _repo(
      db,
      _FailingAdapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'offline',
        ),
      ),
    );

    await expectLater(repo.refreshFromApi(), throwsA(isA<Exception>()));
    expect(await db.select(db.reciters).get(), isEmpty);
  });
}
