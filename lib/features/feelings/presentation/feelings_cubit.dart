import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import '../data/feelings_repository.dart';
import '../domain/feeling.dart';
import 'feelings_state.dart';

// One import keeps the four cubits of this feature together: the router and
// the frozen doubles construct them side by side, and a barrel means the split
// below is invisible to them.
export 'feeling_verses_cubit.dart';
export 'saved_verses_cubit.dart';
export 'verse_detail_cubit.dart';

/// Q43: catalog, hero and the live saved count.
class FeelingsCubit extends Cubit<FeelingsState> {
  FeelingsCubit(this._repo) : super(const FeelingsState.loading());

  final FeelingsRepository _repo;

  Future<void> start() async {
    try {
      final count = await _repo.savedCount();
      emit(
        FeelingsState.ready(
          feelings: FeelingsCatalog.ordered,
          heroExcerpt: FeelingsCatalog.heroExcerpt,
          savedCount: count,
        ),
      );
    } on Object catch (error, stackTrace) {
      appLog(
        'feelings load failed',
        name: 'quran_yahdi/feelings',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const FeelingsState.failed());
    }
  }
}
