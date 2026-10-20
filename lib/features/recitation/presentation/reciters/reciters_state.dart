import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/reciter_info.dart';

part 'reciters_state.freezed.dart';

@freezed
sealed class RecitersState with _$RecitersState {
  const factory RecitersState.loading() = RecitersLoading;

  const factory RecitersState.ready({
    @Default(<ReciterInfo>[]) List<ReciterInfo> reciters,
    @Default('') String query,
    @Default(false) bool dataError,
  }) = RecitersReady;

  const factory RecitersState.failed() = RecitersFailed;
}

/// Legacy alias for the pre-rename concrete class (frozen suite).
typedef RecitersError = RecitersFailed;

/// Legacy accessor: the failed state carries no diagnostic any more (the
/// localized error pane is the UI contract), but the frozen suite still
/// reads `message`.
extension RecitersFailedMessage on RecitersFailed {
  String get message => 'failed';
}
