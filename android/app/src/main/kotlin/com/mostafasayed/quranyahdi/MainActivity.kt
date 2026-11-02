package com.mostafasayed.quranyahdi

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
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
                "notificationsEnabled" ->
                    result.success(NotificationManagerCompat.from(this).areNotificationsEnabled())

                "exactAlarmsAllowed" -> result.success(exactAlarmsAllowed())

                "batteryOptimizationIgnored" -> result.success(batteryOptimizationIgnored())

                "openBatteryOptimizationSettings" -> result.success(
                    startSettings(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)),
                )

                "openExactAlarmSettings" -> result.success(openExactAlarmSettings())

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
