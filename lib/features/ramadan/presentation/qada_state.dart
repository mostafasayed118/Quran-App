import 'package:freezed_annotation/freezed_annotation.dart';

part 'qada_state.freezed.dart';

@freezed
sealed class QadaState with _$QadaState {
  const factory QadaState.loading() = QadaLoading;

  const factory QadaState.failed() = QadaFailed;

  const factory QadaState.ready({
    @Default(<DateTime>[]) List<DateTime> dates,
  }) = QadaReady;
}
