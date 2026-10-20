import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../data/hijri_service.dart';
import 'hijri_state.dart';

/// The Hijri calendar screen: one month grid plus today's header.
class HijriCubit extends Cubit<HijriState> {
  /// Creates the cubit and shows the current Hijri month.
  ///
  /// The first render is fire-and-forget: the state moves from loading to
  /// ready on its own.
  HijriCubit({required HijriService service})
      : _service = service,
        super(const HijriState.loading()) {
    unawaited(jumpToToday());
  }

  final HijriService _service;

  /// Shows the given Hijri month and emits the ready state.
  ///
  /// The grid is Saturday-first: [offset] is the number of empty cells
  /// before day 1 of the month.
  Future<void> show(int hijriYear, int hijriMonth) async {
    final length = _service.daysInMonth(hijriYear, hijriMonth);
    final firstGregorian = _service.toGregorian(hijriYear, hijriMonth, 1);
    // Saturday-first grid: Dart weekday Mon=1..Sun=7.
    final offset = (firstGregorian.weekday + 1) % 7;
    final todayHijri = _service.fromGregorian(DateTime.now());
    final cells = <HijriCell>[
      for (var day = 1; day <= length; day++)
        HijriCell(
          hDay: day,
          gDay: _service.toGregorian(hijriYear, hijriMonth, day).day,
          isToday: todayHijri.hYear == hijriYear &&
              todayHijri.hMonth == hijriMonth &&
              todayHijri.hDay == day,
        ),
    ];
    final todayHeader =
        '${_arabic(todayHijri.hDay)} ${_service.monthName(todayHijri.hYear, todayHijri.hMonth)} ${_arabic(todayHijri.hYear)}';
    if (isClosed) return;
    emit(HijriState.ready(
      month: hijriMonth,
      year: hijriYear,
      monthName: _service.monthName(hijriYear, hijriMonth),
      offset: offset,
      cells: cells,
      todayHeader: todayHeader,
    ));
  }

  String _arabic(int n) => n.toArabicIndic;

  /// Shows the next month (rolls the year over from month 12).
  Future<void> next() async {
    final state = this.state;
    if (state is! HijriReady) return;
    final month = state.month == 12 ? 1 : state.month + 1;
    final year = state.month == 12 ? state.year + 1 : state.year;
    await show(year, month);
  }

  /// Shows the previous month (rolls the year back from month 1).
  Future<void> prev() async {
    final state = this.state;
    if (state is! HijriReady) return;
    final month = state.month == 1 ? 12 : state.month - 1;
    final year = state.month == 1 ? state.year - 1 : state.year;
    await show(year, month);
  }

  /// Shows the month that contains today.
  Future<void> jumpToToday() async {
    final now = DateTime.now();
    final hijri = _service.fromGregorian(now);
    await show(hijri.hYear, hijri.hMonth);
  }
}
