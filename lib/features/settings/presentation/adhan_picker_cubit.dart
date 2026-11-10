import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran_yahdi/core/domain/adhan_player.dart';
import 'package:quran_yahdi/core/domain/adhan_preferences.dart';
import 'package:quran_yahdi/core/utils/app_log.dart';

import 'adhan_picker_state.dart';

/// Owns the adhan picker.
///
/// Deliberately NOT [SettingsCubit]: that one is created once per settings
/// route, and sharing it here would leak picker state (and a live preview)
/// between visits. The router builds this cubit through `RouteCubitScope`.
///
/// Re-planning is injected as a callback rather than as four ports, the same
/// shape `BackupService` uses: the picker needs "tell the reminder engine the
/// schedule changed", not the city/prayer machinery behind it.
class AdhanPickerCubit extends Cubit<AdhanPickerState> {
  /// Creates the cubit; side-effect free. The route scope calls [start].
  AdhanPickerCubit({
    required AdhanPreferences prefs,
    required AdhanPlayer player,
    required Future<void> Function() reschedule,
  })  : _prefs = prefs,
        _player = player,
        _reschedule = reschedule,
        super(const AdhanPickerState.loading());

  final AdhanPreferences _prefs;
  final AdhanPlayer _player;
  final Future<void> Function() _reschedule;

  Future<void> _mutations = Future<void>.value();

  /// Runs [op] after every mutation already queued, so two fast taps cannot
  /// interleave their writes and leave storage disagreeing with the screen.
  Future<void> _serialized(Future<void> Function() op) {
    final result = _mutations.then<void>((_) => op());
    _mutations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Reads the stored choices and emits them.
  Future<void> start() async {
    try {
      final adhanId = await _prefs.adhanId();
      final fajrId = await _prefs.fajrAdhanId();
      if (isClosed) return;
      emit(AdhanPickerState.ready(adhanId: adhanId, fajrAdhanId: fajrId));
    } on Object catch (error, stackTrace) {
      _log('load', error, stackTrace);
      if (isClosed) return;
      emit(const AdhanPickerState.failed());
    }
  }

  /// Persists the global choice and re-plans the reminders.
  Future<void> select(String id) => _serialized(() async {
        final current = _readyState();
        if (current == null) return;
        // Spec section 7: a running preview must not outlive the choice it was
        // auditioning, or the old reciter keeps playing under the new tick.
        await stopPreview();
        try {
          await _prefs.setAdhanId(id);
        } on Object catch (error, stackTrace) {
          _log('select', error, stackTrace);
          return;
        }
        final after = _readyState();
        if (after == null) return;
        emit(after.copyWith(adhanId: id));
        await _rescheduleBestEffort();
      });

  /// Persists the Fajr override; null means "same as the global choice".
  Future<void> selectFajr(String? id) => _serialized(() async {
        final current = _readyState();
        if (current == null) return;
        await stopPreview();
        try {
          await _prefs.setFajrAdhanId(id);
        } on Object catch (error, stackTrace) {
          _log('selectFajr', error, stackTrace);
          return;
        }
        final after = _readyState();
        if (after == null) return;
        emit(after.copyWith(fajrAdhanId: id));
        await _rescheduleBestEffort();
      });

  /// Auditions [id]; stops whatever preview was already playing first.
  Future<void> preview(String id) async {
    await stopPreview();
    final current = _readyState();
    if (current == null) return;
    emit(current.copyWith(previewingId: id));
    try {
      await _player.preview(id);
    } on Object catch (error, stackTrace) {
      _log('preview', error, stackTrace);
      final after = _readyState();
      if (after == null) return;
      emit(after.copyWith(previewingId: null));
    }
  }

  /// Stops an active preview; a no-op when nothing is playing.
  Future<void> stopPreview() async {
    final current = _readyState();
    if (current == null || current.previewingId == null) return;
    emit(current.copyWith(previewingId: null));
    try {
      await _player.stop();
    } on Object catch (error, stackTrace) {
      _log('stopPreview', error, stackTrace);
    }
  }

  /// Re-planning is best-effort: the choice is already persisted and shown,
  /// and the next boot or settings load re-plans.
  Future<void> _rescheduleBestEffort() async {
    try {
      await _reschedule();
    } on Object catch (error, stackTrace) {
      _log('reschedule', error, stackTrace);
    }
  }

  /// The state a mutation may build on, or null when there is nothing
  /// confirmed to build on (closed, still loading, or failed).
  AdhanPickerReady? _readyState() {
    if (isClosed) return null;
    final current = state;
    return current is AdhanPickerReady ? current : null;
  }

  void _log(String operation, Object error, StackTrace stackTrace) {
    appLog(
      'adhan picker $operation failed',
      name: 'quran_yahdi/adhan',
      error: error.runtimeType,
      stackTrace: stackTrace,
    );
  }
}
