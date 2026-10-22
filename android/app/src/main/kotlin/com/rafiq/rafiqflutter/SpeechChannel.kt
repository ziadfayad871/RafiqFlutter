package com.rafiq.rafiqflutter

import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class SpeechChannel(
    private val context: android.content.Context
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "rafiq/speech"
        const val EVENT_CHANNEL = "rafiq/speech/events"
        const val REQUEST_LISTEN = 7002
    }

    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var pendingSpeak: Pair<String, String>? = null
    private var eventSink: EventChannel.EventSink? = null
    private var listening = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                val locale = call.argument<String>("locale") ?: "ar"
                speak(text, locale, result)
            }
            "stopSpeaking" -> {
                tts?.stop()
                result.success(true)
            }
            "startListening" -> {
                val locale = call.argument<String>("locale") ?: "ar"
                startListening(locale, result)
            }
            "stopListening" -> {
                stopListening()
                result.success(true)
            }
            "isListening" -> result.success(listening)
            else -> result.notImplemented()
        }
    }

    private fun speak(text: String, locale: String, result: MethodChannel.Result) {
        if (text.isBlank()) {
            result.success(false)
            return
        }
        val engine = tts
        if (engine == null) {
            pendingSpeak = text to locale
            initTts()
            result.success(true)
            return
        }
        if (!ttsReady) {
            pendingSpeak = text to locale
            result.success(true)
            return
        }
        val status = engine.setLanguage(Locale(locale))
        engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, "rafiq")
        result.success(status != TextToSpeech.LANG_MISSING_DATA)
    }

    private fun initTts() {
        tts = TextToSpeech(context) { status ->
            ttsReady = status == TextToSpeech.SUCCESS
            if (ttsReady) {
                tts?.language = Locale("ar")
                val pending = pendingSpeak
                pendingSpeak = null
                if (pending != null) speak(pending.first, pending.second, MethodChannel.Result { _, _ -> })
            }
        }
    }

    private fun startListening(locale: String, result: MethodChannel.Result) {
        val activity = context as? android.app.Activity ?: run {
            result.error("no_activity", "activity not available", null)
            return
        }
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        listening = true
        runCatching {
            activity.startActivityForResult(intent, REQUEST_LISTEN)
            result.success(true)
        }.onFailure {
            listening = false
            result.error("listen_failed", it.message, null)
        }
    }

    private fun stopListening() {
        listening = false
        eventSink?.success(mapOf("type" to "stopped"))
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_LISTEN) return
        listening = false
        val results = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
        val text = results?.firstOrNull().orEmpty()
        eventSink?.success(mapOf("type" to "result", "text" to text))
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
