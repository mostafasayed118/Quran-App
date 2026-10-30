import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';

import 'support/test_db.dart';

class _FailingClient extends http.BaseClient {
  _FailingClient(this.onSend);

  final Future<http.StreamedResponse> Function(http.BaseRequest) onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      onSend(request);
}

ReciterRepository _repo(AppDatabase db, http.Client client) =>
    ReciterRepository(
      db,
      client: client,
      apiEndpointOverride: 'https://catalog.example.test/reciters',
    );

void main() {
  late AppDatabase db;

  setUp(() {
    db = newTestDb();
  });

  tearDown(() async => db.close());

  test('a timeout is surfaced and leaves the catalog untouched', () async {
    final repo = _repo(
      db,
      _FailingClient((_) async => throw TimeoutException('catalog timeout')),
    );

    await expectLater(repo.refreshFromApi(), throwsA(isA<TimeoutException>()));
    expect(await db.select(db.reciters).get(), isEmpty);
  });

  test('a 5xx response is surfaced and leaves the catalog untouched', () async {
    final repo = _repo(
      db,
      _FailingClient(
        (_) async => http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode('')),
          503,
        ),
      ),
    );

    await expectLater(repo.refreshFromApi(), throwsA(isA<StateError>()));
    expect(await db.select(db.reciters).get(), isEmpty);
  });

  test('a connection failure is surfaced, never a partial rewrite', () async {
    final repo = _repo(
      db,
      _FailingClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(repo.refreshFromApi(), throwsA(isA<Exception>()));
    expect(await db.select(db.reciters).get(), isEmpty);
  });
}
