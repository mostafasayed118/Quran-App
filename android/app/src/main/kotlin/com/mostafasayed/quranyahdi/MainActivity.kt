package com.mostafasayed.quranyahdi

import android.app.ActivityManager
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Reminder reliability diagnostics (`quran_yahdi/reminder_diagnostics`).
 *
 * The Android side of the settings section: the OS — not the app — knows
 * whether notifications may be posted, whether exact alarms are allowed and
 * whether the app is exempt from battery optimisation. Every answer is read
 * at call time so a permission revoked in the system settings while the app
 * is backgrounded is reported on the next resume.
 *
 * The channel is deliberately read-only except for the two "send the user to
 * the right system screen" methods; nothing here schedules or cancels a
 * reminder.
 */
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REMINDER_DIAGNOSTICS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "notificationsEnabled" -> {
                    try {
                        result.success(
                            NotificationManagerCompat.from(this).areNotificationsEnabled(),
                        )
                    } catch (error: Exception) {
                        result.error("probe_failed", error.message, null)
                    }
                }

                "exactAlarmsAllowed" -> {
                    try {
                        result.success(exactAlarmsAllowed())
                    } catch (error: Exception) {
                        result.error("probe_failed", error.message, null)
                    }
                }

                "batteryOptimizationIgnored" -> result.success(batteryOptimizationIgnored())

                "openBatteryOptimizationSettings" -> result.success(
                    startSettings(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)),
                )

                "openExactAlarmSettings" -> result.success(openExactAlarmSettings())

                "alarmExists" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("bad_args", "id is required", null)
                    } else {
                        // Always reply: a native throw before `result` leaves
                        // Dart's invokeMethod waiting forever and the apply
                        // guard stuck. An error is treated as "unknown" and
                        // re-armed on the Dart side, which is idempotent.
                        try {
                            result.success(alarmExists(id))
                        } catch (error: Exception) {
                            result.error("probe_failed", error.message, null)
                        }
                    }
                }

                "lastExitReason" -> result.success(lastExitReason())

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Exact alarms are unrestricted before Android 12; from Android 12 on the
     * OS owns the permission and Android 14 lets the user revoke it.
     */
    private fun exactAlarmsAllowed(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return false
        return alarmManager.canScheduleExactAlarms()
    }

    /**
     * Null when the OEM ROM cannot answer: the Dart side then shows the
     * "check it yourself" instruction instead of a verdict the device never
     * produced.
     */
    private fun batteryOptimizationIgnored(): Boolean? {
        return try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            powerManager?.isIgnoringBatteryOptimizations(packageName)
        } catch (error: RuntimeException) {
            null
        }
    }

    /** Android 12+ only: below it there is no exact-alarm screen to open. */
    private fun openExactAlarmSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return startSettings(
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, packageUri()),
        )
    }

    private fun packageUri(): Uri = Uri.parse("package:$packageName")

    /**
     * Whether the notification plugin's scheduled alarm for [id] is still
     * registered with `AlarmManager`.
     *
     * The identity of the plugin's `PendingIntent` is the request code (the
     * notification id), the receiver component and an intent with no action
     * or data (see `FlutterLocalNotificationsPlugin#getBroadcastPendingIntent`
     * in flutter_local_notifications 22.3.2). `FLAG_NO_CREATE` therefore
     * returns null exactly when the OS no longer holds the alarm.
     *
     * This is deliberately a probe, not a scheduling path: it never creates
     * the PendingIntent.
     */
    private fun alarmExists(id: Int): Boolean {
        // The plugin builds its PendingIntent with the application context;
        // use the same one here so an Activity teardown cannot affect the
        // probe. Identity (id / receiver / no action/data) is unchanged.
        val context = applicationContext
        val intent = Intent(context, ScheduledNotificationReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        return pending != null
    }

    /**
     * The reason the previous process ended, as `ApplicationExitInfo` reports
     * it (API 30+); null below that or when the ROM cannot answer.
     */
    private fun lastExitReason(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        return try {
            val activityManager =
                getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            activityManager
                ?.getHistoricalProcessExitReasons(packageName, 0, 1)
                ?.firstOrNull()
                ?.reason
                ?.toString()
        } catch (error: Exception) {
            null
        }
    }

    /**
     * Opens a system screen; false when the ROM ships no activity for it (the
     * settings tile then stays as it was — an OEM gap must not crash the tap).
     */
    private fun startSettings(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (error: Exception) {
            false
        }
    }

    private companion object {
        const val REMINDER_DIAGNOSTICS_CHANNEL = "quran_yahdi/reminder_diagnostics"
    }
}
