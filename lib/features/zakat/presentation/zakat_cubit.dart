import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/zakat_calculator.dart';
import 'zakat_state.dart';

/// The zakat screen: the nisab inputs and the computed result.
class ZakatCubit extends Cubit<ZakatState> {
  /// Creates the cubit with the ready state (the inputs start empty).
  ZakatCubit() : super(const ZakatState.ready());

  /// Picks which metal the nisab is measured in (gold or silver).
  void setNisabBySilver(bool bySilver) {
    if (isClosed) return;
    final state = this.state as ZakatReady;
    emit(state.copyWith(nisabBySilver: bySilver));
    _recompute();
  }

  /// Sets the gold weight (a decimal string) and recomputes the result.
  void setGoldGrams(String text) =>
      _setField((s) => s.copyWith(goldGrams: text));

  /// Sets the silver weight (a decimal string) and recomputes the result.
  void setSilverGrams(String text) =>
      _setField((s) => s.copyWith(silverGrams: text));

  /// Sets the gold price per gram (a decimal string) and recomputes.
  void setGoldPrice(String text) =>
      _setField((s) => s.copyWith(goldPrice: text));

  /// Sets the silver price per gram (a decimal string) and recomputes.
  void setSilverPrice(String text) =>
      _setField((s) => s.copyWith(silverPrice: text));

  /// Sets the cash amount (a decimal string) and recomputes the result.
  void setCash(String text) => _setField((s) => s.copyWith(cash: text));

  /// Sets the debts amount (a decimal string) and recomputes the result.
  void setDebts(String text) => _setField((s) => s.copyWith(debts: text));

  void _setField(ZakatReady Function(ZakatReady) transform) {
    if (isClosed) return;
    final state = this.state as ZakatReady;
    emit(transform(state));
    _recompute();
  }

  void _recompute() {
    if (isClosed) return;
    final state = this.state as ZakatReady;
    emit(state.copyWith(
      result: const ZakatCalculator().compute(
        ZakatInput(
          goldGrams: parseDecimal(state.goldGrams),
          silverGrams: parseDecimal(state.silverGrams),
          cash: parseDecimal(state.cash),
          debts: parseDecimal(state.debts),
          nisabBySilver: state.nisabBySilver,
        ),
        goldPricePerGram: parseDecimal(state.goldPrice),
        silverPricePerGram: parseDecimal(state.silverPrice),
      ),
    ));
  }
}
