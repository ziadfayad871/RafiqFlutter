package com.rafiq.rafiqflutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var speechChannel: SpeechChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, LauncherChannel.CHANNEL)
            .setMethodCallHandler(LauncherChannel(applicationContext))
        MethodChannel(messenger, AlarmChannel.CHANNEL)
            .setMethodCallHandler(AlarmChannel(applicationContext))
        MethodChannel(messenger, LocationChannel.CHANNEL)
            .setMethodCallHandler(LocationChannel(applicationContext))

        speechChannel = SpeechChannel(applicationContext)
        MethodChannel(messenger, SpeechChannel.METHOD_CHANNEL)
            .setMethodCallHandler(speechChannel)
        EventChannel(messenger, SpeechChannel.EVENT_CHANNEL)
            .setStreamHandler(speechChannel)

        RafiqNotifications.ensureChannels(applicationContext)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        speechChannel?.handleActivityResult(requestCode, resultCode, data)
    }
}
