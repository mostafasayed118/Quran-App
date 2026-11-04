import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../core/l10n/app_locale_controller.dart';
import '../features/notifications/data/notifications_binding.dart';
import 'bootstrap.dart';
import 'di/injector.dart';

/// The WorkManager task name the dispatcher answers to.
const String reminderRefreshTask = 'reminderRefresh';

/// Stable unique name, so re-registering on every app start keeps one task.
const String reminderRefreshUniqueName = 'quran_yahdi_reminder_refresh';

/// How often the background isolate re-composes the rolling plan.
///
/// WorkManager's floor is 15 minutes. 30 keeps the wakeups moderate while still
/// running right after a boot that lasted longer than half an hour — the case
/// where the platform's own restore would otherwise replay stale instants.
const Duration reminderRefreshFrequency = Duration(minutes: 30);

/// How many stamp lines the device check keeps (see [stampReminderRefresh]).
const int stampHistory = 40;

/// Entry point invoked by the OS in a background isolate.
///
/// Must stay a top-level function annotated for AOT: the platform resolves it
/// by handle, not by name.
@pragma('vm:entry-point')
void reminderTaskDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != reminderRefreshTask) {
      // Another task registered by this app: nothing to do here, and never
      // report a failure that would retry work this handler does not own.
      return true;
    }
    return runReminderRefreshTask(refreshRemindersForBackground);
  });
}

/// Runs the background body and reports success without ever throwing.
///
/// A thrown task is an opaque platform-level failure; a `false` return is the
/// documented "retry later" signal. Split out so the contract is testable
/// without an isolate.
Future<bool> runReminderRefreshTask(Future<void> Function() body) async {
  try {
    await body();
    return true;
  } on Object catch (error, stackTrace) {
    // A background isolate has no UI: this log is the only trace the device
    // check can read (`adb logcat -s flutter`).
    dev.log(
      'reminder refresh task failed',
      name: 'quran_yahdi/background',
      error: error.runtimeType,
      stackTrace: stackTrace,
    );
    await stampReminderRefresh('failed:${error.runtimeType}');
    return false;
  }
}

/// Durable record of a background run, for the on-device check.
///
/// `adb shell run-as <pkg> cat cache/reminder_refresh_stamp.txt` answers "did
/// the isolate ever run?" — a background isolate prints nothing and a silent
/// failure looks exactly like a task that never started. Uses the temp dir on
/// purpose: it needs no plugin, so the stamp cannot fail for the same reason
/// the refresh did.
///
/// Keeps the last [stampHistory] lines: the task runs every half hour, so an
/// append-only file would grow without bound on a phone that is never updated.
Future<void> stampReminderRefresh(String outcome) async {
  try {
    final file =
        File('${Directory.systemTemp.path}/reminder_refresh_stamp.txt');
    final kept = <String>[];
    if (file.existsSync()) {
      final lines = await file.readAsLines();
      if (lines.length >= stampHistory) {
        kept.addAll(lines.sublist(lines.length - stampHistory + 1));
      } else {
        kept.addAll(lines);
      }
    }
    kept.add('${DateTime.now().toIso8601String()} $outcome');
    await file.writeAsString('${kept.join('\n')}\n', flush: true);
  } on Object {
    // Diagnostics only: losing the stamp must never fail the refresh.
  }
}

/// Re-composes the reminder plan from the persisted state inside the
/// background isolate.
///
/// The isolate has no access to the app's object graph, so it builds its own
/// (the same composition root) and initializes the notification plugin before
/// handing it a plan — the plugin is the only writer of the alarms, and a plan
/// queued against an uninitialized binding would be lost with the isolate.
Future<void> refreshRemindersForBackground() async {
  // First thing, before any plugin: proves the isolate actually started.
  await stampReminderRefresh('start');
  dev.log('reminder refresh task started', name: 'quran_yahdi/background');
  WidgetsFlutterBinding.ensureInitialized();
  // Plugins that register Dart-side handlers in a secondary isolate need this;
  // it is a no-op when the platform already registered them.
  try {
    DartPluginRegistrant.ensureInitialized();
  } on Object {
    // Best-effort: an unsupported host must not fail the whole task.
  }
  await configureDependencies();
  // The copy, the channel name and the action label are composed when an alarm
  // is scheduled, so the isolate must know the user's language first.
  await getIt<AppLocaleController>().load();
  await getIt<NotificationsBinding>().init();
  await runBootReminderSchedule();
  await stampReminderRefresh('ok');
}
