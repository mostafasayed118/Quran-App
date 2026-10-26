import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/arabic_numbers.dart';
import '../data/hijri_service.dart';
import 'hijri_state.dart';

/// The Hijri calendar screen: one month grid plus today's header.
class HijriCubit extends Cubit<HijriState> {
  /// Creates the cubit; the constructor is side-effect free and does no
  /// work — [start] performs the first load.
  HijriCubit({required HijriService service})
      : _service = service,
        super(const HijriState.loading());

  /// Starts the route-scoped load; the constructor intentionally does no
  /// work. The route scope calls this once, from the widget lifecycle.
  Future<void> start() => jumpToToday();

  final HijriService _service;

  /// Shows the given Hijri month and emits the ready state.
  ///
  /// The grid is Saturday-first: [offset] is the number of empty cells
  /// before day 1 of the month.
  Future<void> show(int hijriYear, int hijriMonth) async {
    try {
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
    } on Object catch (error, stackTrace) {
      dev.log('hijri load failed',
          name: 'quran_yahdi/hijri', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const HijriState.failed());
    }
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
    try {
      final now = DateTime.now();
      final hijri = _service.fromGregorian(now);
      await show(hijri.hYear, hijri.hMonth);
    } on Object catch (error, stackTrace) {
      dev.log('hijri today failed',
          name: 'quran_yahdi/hijri', error: error, stackTrace: stackTrace);
      if (isClosed) return;
      emit(const HijriState.failed());
    }
  }
}
