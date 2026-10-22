package com.rafiq.rafiqflutter

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.max

class AlarmChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "rafiq/alarms"
        const val PRAYER_PREFS = "rafiq_prayer_alarm"
        const val FOCUS_PREFS = "rafiq_focus_alarm"
        const val PRAYER_REQUEST = 4101
        const val FOCUS_REQUEST = 4202
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedulePrayer" -> {
                val triggerAt = call.argument<Number>("triggerAt")?.toLong() ?: 0L
                val name = call.argument<String>("prayerName") ?: ""
                val time = call.argument<String>("prayerTime") ?: ""
                schedulePrayer(triggerAt, name, time)
                result.success(true)
            }
            "cancelPrayer" -> {
                cancelPrayer()
                result.success(true)
            }
            "scheduleFocus" -> {
                val endAt = call.argument<Number>("endAt")?.toLong() ?: 0L
                scheduleFocus(endAt)
                result.success(true)
            }
            "cancelFocus" -> {
                cancelFocus()
                result.success(true)
            }
            "canScheduleExact" -> result.success(canScheduleExact())
            "openExactAlarmSettings" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    runCatching {
                        context.startActivity(
                            Intent(android.provider.Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                    }
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun schedulePrayer(triggerAt: Long, prayerName: String, prayerTime: String) {
        context.getSharedPreferences(PRAYER_PREFS, Context.MODE_PRIVATE).edit()
            .putLong("trigger_at", triggerAt)
            .putString("prayer_name", prayerName)
            .putString("prayer_time", prayerTime)
            .apply()
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            putExtra("prayer_name", prayerName)
            putExtra("prayer_time", prayerTime)
        }
        val pending = PendingIntent.getBroadcast(
            context,
            PRAYER_REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        alarmManager.cancel(pending)
        if (canScheduleExact()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        }
    }

    private fun cancelPrayer() {
        context.getSharedPreferences(PRAYER_PREFS, Context.MODE_PRIVATE).edit()
            .remove("trigger_at")
            .apply()
        val intent = Intent(context, PrayerAlarmReceiver::class.java)
        val pending = PendingIntent.getBroadcast(
            context,
            PRAYER_REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        context.getSystemService(AlarmManager::class.java)?.cancel(pending)
    }

    private fun scheduleFocus(endAt: Long) {
        context.getSharedPreferences(FOCUS_PREFS, Context.MODE_PRIVATE).edit()
            .putLong("end_at", endAt)
            .apply()
        val pending = focusPendingIntent()
        val alarmManager = context.getSystemService(AlarmManager::class.java) ?: return
        alarmManager.cancel(pending)
        if (canScheduleExact()) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endAt, pending)
        } else {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endAt, pending)
        }
    }

    private fun cancelFocus() {
        context.getSharedPreferences(FOCUS_PREFS, Context.MODE_PRIVATE).edit()
            .remove("end_at")
            .apply()
        context.getSystemService(AlarmManager::class.java)?.cancel(focusPendingIntent())
    }

    private fun focusPendingIntent(): PendingIntent {
        val intent = Intent(context, FocusAlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            FOCUS_REQUEST,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun canScheduleExact(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return context.getSystemService(AlarmManager::class.java)?.canScheduleExactAlarms() == true
    }
}

class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val name = intent.getStringExtra("prayer_name") ?: "الصلاة"
        val time = intent.getStringExtra("prayer_time") ?: ""
        RafiqNotifications.showPrayer(context, name, time)
    }
}

class FocusAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        RafiqNotifications.showFocusComplete(context)
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> Unit
            else -> return
        }
        RafiqNotifications.ensureChannels(context)
        val prayer = context.getSharedPreferences(AlarmChannel.PRAYER_PREFS, Context.MODE_PRIVATE)
        val triggerAt = prayer.getLong("trigger_at", 0L)
        if (triggerAt > System.currentTimeMillis()) {
            val name = prayer.getString("prayer_name", "") ?: ""
            val time = prayer.getString("prayer_time", "") ?: ""
            val channel = AlarmChannel(context)
            val pending = PendingIntent.getBroadcast(
                context,
                AlarmChannel.PRAYER_REQUEST,
                Intent(context, PrayerAlarmReceiver::class.java).apply {
                    putExtra("prayer_name", name)
                    putExtra("prayer_time", time)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(AlarmManager::class.java)
            alarmManager?.let { manager ->
                manager.cancel(pending)
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()) {
                    manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
                } else {
                    manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
                }
            }
        }
        val focus = context.getSharedPreferences(AlarmChannel.FOCUS_PREFS, Context.MODE_PRIVATE)
        val endAt = focus.getLong("end_at", 0L)
        if (endAt > System.currentTimeMillis()) {
            val pending = PendingIntent.getBroadcast(
                context,
                AlarmChannel.FOCUS_REQUEST,
                Intent(context, FocusAlarmReceiver::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = context.getSystemService(AlarmManager::class.java)
            alarmManager?.let { manager ->
                manager.cancel(pending)
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endAt, pending)
            }
        }
    }
}

object RafiqNotifications {
    const val PRAYER_CHANNEL = "prayer_times"
    const val FOCUS_CHANNEL = "focus_sessions"
    private const val PRAYER_NOTIFICATION_ID = 2001
    private const val FOCUS_NOTIFICATION_ID = 3001

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val prayer = NotificationChannel(
            PRAYER_CHANNEL,
            "مواقيت الصلاة",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "تنبيه عند دخول وقت كل صلاة"
            enableVibration(true)
        }
        val focus = NotificationChannel(
            FOCUS_CHANNEL,
            "جلسات التركيز",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "تنبيه عند انتهاء جلسة التركيز"
            enableVibration(true)
        }
        manager.createNotificationChannels(listOf(prayer, focus))
    }

    fun showPrayer(context: Context, prayerName: String, time: String) {
        if (!canPost(context)) return
        val notification = android.app.Notification.Builder(context, PRAYER_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("حان وقت صلاة $prayerName")
            .setContentText("موعد الصلاة $time — تقبل الله طاعتك")
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
            .build()
        runCatching {
            context.getSystemService(NotificationManager::class.java)
                ?.notify(PRAYER_NOTIFICATION_ID, notification)
        }
    }

    fun showFocusComplete(context: Context) {
        if (!canPost(context)) return
        val notification = android.app.Notification.Builder(context, FOCUS_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("انتهت جلسة التركيز")
            .setContentText("أحسنت. خذ نفسًا، وواصل يومك بهدوء.")
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
            .build()
        runCatching {
            context.getSystemService(NotificationManager::class.java)
                ?.notify(FOCUS_NOTIFICATION_ID, notification)
        }
    }

    fun showTest(context: Context) {
        if (!canPost(context)) return
        val notification = android.app.Notification.Builder(context, PRAYER_CHANNEL)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("تنبيه تجريبي")
            .setContentText("هكذا سيصلك تنبيه الصلاة من رفيق.")
            .setAutoCancel(true)
            .setContentIntent(openAppIntent(context))
            .build()
        runCatching {
            context.getSystemService(NotificationManager::class.java)
                ?.notify(PRAYER_NOTIFICATION_ID + 1, notification)
        }
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            900,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun canPost(context: Context): Boolean {
        val granted = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED
        return granted &&
            context.getSystemService(NotificationManager::class.java)?.areNotificationsEnabled() == true
    }
}
