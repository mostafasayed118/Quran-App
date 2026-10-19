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

  const factory RecitersState.error({required String message}) = RecitersError;
}
