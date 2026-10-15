import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/zakat_calculator.dart';
import 'zakat_state.dart';

class ZakatCubit extends Cubit<ZakatState> {
  ZakatCubit() : super(const ZakatState.ready());

  void setNisabBySilver(bool bySilver) {
    if (isClosed) return;
    final state = this.state as ZakatReady;
    emit(state.copyWith(nisabBySilver: bySilver));
    _recompute();
  }

  void setGoldGrams(String text) => _setField((s) => s.copyWith(goldGrams: text));
  void setSilverGrams(String text) =>
      _setField((s) => s.copyWith(silverGrams: text));
  void setGoldPrice(String text) => _setField((s) => s.copyWith(goldPrice: text));
  void setSilverPrice(String text) =>
      _setField((s) => s.copyWith(silverPrice: text));
  void setCash(String text) => _setField((s) => s.copyWith(cash: text));
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
