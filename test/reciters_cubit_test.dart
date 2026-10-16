import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_yahdi/core/db/app_database.dart';
import 'package:quran_yahdi/features/recitation/data/reciter_repository.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_cubit.dart';
import 'package:quran_yahdi/features/recitation/presentation/reciters/reciters_state.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('stream error lands in the existing error state', () async {
    final cubit = RecitersCubit(repo: _ThrowingReciterRepository(db));
    expect(cubit.state, isA<RecitersLoading>());

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<RecitersError>());
    expect((cubit.state as RecitersError).message, isNotEmpty);

    await cubit.close();
  });
}

class _ThrowingReciterRepository extends ReciterRepository {
  _ThrowingReciterRepository(super.db);

  @override
  Stream<List<ReciterRow>> watchAll() =>
      Stream.error(StateError('watch failed'));
}
