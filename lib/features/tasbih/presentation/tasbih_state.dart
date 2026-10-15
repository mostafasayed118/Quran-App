import 'package:freezed_annotation/freezed_annotation.dart';

part 'tasbih_state.freezed.dart';

@freezed
sealed class TasbihState with _$TasbihState {
  const factory TasbihState.ready({
    @Default(0) int count,
    @Default(33) int target,
    @Default(false) bool reachedTarget,
  }) = TasbihReady;
}
