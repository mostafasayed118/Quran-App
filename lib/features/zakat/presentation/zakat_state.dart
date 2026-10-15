import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/zakat_calculator.dart';

part 'zakat_state.freezed.dart';

@freezed
sealed class ZakatState with _$ZakatState {
  const factory ZakatState.ready({
    @Default(true) bool nisabBySilver,
    @Default('') String goldGrams,
    @Default('') String silverGrams,
    @Default('') String goldPrice,
    @Default('') String silverPrice,
    @Default('') String cash,
    @Default('') String debts,
    @Default(ZakatResult(
      zakatable: 0,
      nisabValue: 0,
      due: false,
      amount: 0,
    ))
    ZakatResult result,
  }) = ZakatReady;
}
