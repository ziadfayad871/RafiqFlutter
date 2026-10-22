package com.rafiq.rafiqflutter

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.text.Collator
import java.util.Locale

class LauncherChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "rafiq/launcher"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listApps" -> result.success(loadInstalledApps())
            "launchApp" -> {
                val packageName = call.argument<String>("packageName")
                val activityName = call.argument<String>("activityName")
                if (packageName.isNullOrBlank() || activityName.isNullOrBlank()) {
                    result.error("invalid", "packageName and activityName are required", null)
                    return
                }
                val intent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    component = android.content.ComponentName(packageName, activityName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED)
                }
                runCatching { context.startActivity(intent) }
                    .onSuccess { result.success(true) }
                    .onFailure { result.error("launch_failed", it.message, null) }
            }
            "launchDock" -> {
                val kind = call.argument<String>("kind")
                val intent = when (kind) {
                    "phone" -> Intent(Intent.ACTION_DIAL)
                    "messages" -> Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:"))
                    "browser" -> Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com"))
                    "camera" -> Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                    else -> null
                }
                if (intent == null) {
                    result.error("invalid", "unknown dock kind", null)
                    return
                }
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                runCatching { context.startActivity(intent) }
                    .onSuccess { result.success(true) }
                    .onFailure { result.error("launch_failed", it.message, null) }
            }
            "dockApps" -> result.success(loadDockApps())
            "openAppSettings" -> result.success(openSettings(Intent(
                android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${context.packageName}")
            )))
            "openLanguageSettings" -> result.success(openSettings(Intent(
                "android.settings.APP_LOCALE_SETTINGS",
                Uri.parse("package:${context.packageName}")
            )))
            "openHomeSettings" -> result.success(openSettings(Intent(
                android.provider.Settings.ACTION_HOME_SETTINGS
            )))
            "isDefaultLauncher" -> result.success(isDefaultLauncher())
            else -> result.notImplemented()
        }
    }

    private fun openSettings(intent: Intent): Boolean = runCatching {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        true
    }.getOrDefault(false)

    private fun isDefaultLauncher(): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolved = context.packageManager.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolved?.activityInfo?.packageName == context.packageName
    }

    private fun loadInstalledApps(): List<Map<String, Any?>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val resolved = context.packageManager.queryIntentActivities(intent, 0)
        val collator = Collator.getInstance(Locale("ar", "EG"))
        val seen = mutableSetOf<String>()
        val apps = mutableListOf<Map<String, Any?>>()
        for (info in resolved) {
            val activity = info.activityInfo ?: continue
            if (activity.packageName == context.packageName) continue
            if (!seen.add(activity.packageName)) continue
            val label = info.loadLabel(context.packageManager)?.toString()
                ?.takeIf { it.isNotBlank() }
                ?: activity.packageName
            apps += mapOf(
                "label" to label,
                "packageName" to activity.packageName,
                "activityName" to activity.name,
                "icon" to drawableToBytes(info.loadIcon(context.packageManager))
            )
        }
        apps.sortedWith(compareBy(collator) { (it["label"] as String) })
    }

    private fun loadDockApps(): List<Map<String, Any?>> {
        val specs = listOf(
            Triple("phone", Intent(Intent.ACTION_DIAL), "الهاتف"),
            Triple("messages", Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:")), "الرسائل"),
            Triple("browser", Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com")), "المتصفح"),
            Triple("camera", Intent(MediaStore.ACTION_IMAGE_CAPTURE), "الكاميرا")
        )
        return specs.map { (kind, intent, fallbackLabel) ->
            @Suppress("DEPRECATION")
            val resolved = context.packageManager.resolveActivity(intent, 0)
            val activity = resolved?.activityInfo
            val label = resolved?.loadLabel(context.packageManager)?.toString()
                ?.takeIf { it.isNotBlank() && it != "Android System" }
                ?: fallbackLabel
            mapOf(
                "kind" to kind,
                "label" to label,
                "packageName" to activity?.packageName,
                "icon" to drawableToBytes(resolved?.loadIcon(context.packageManager))
            )
        }
    }

    private fun drawableToBytes(drawable: Drawable?): ByteArray? = runCatching {
        if (drawable == null) return null
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        val output = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
        output.toByteArray()
    }.getOrNull()
}
