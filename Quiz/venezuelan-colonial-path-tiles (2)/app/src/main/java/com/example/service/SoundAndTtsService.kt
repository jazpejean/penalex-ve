package com.example.service

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.speech.tts.TextToSpeech
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Locale
import kotlin.math.PI
import kotlin.math.sin

class SoundAndTtsService(context: Context) : TextToSpeech.OnInitListener {
    private val scope = CoroutineScope(Dispatchers.Default)
    private var tts: TextToSpeech? = null
    private var ttsReady = false

    init {
        tts = TextToSpeech(context.applicationContext, this)
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale("es", "VE"))
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                tts?.setLanguage(Locale("es", "ES"))
            }
            tts?.setSpeechRate(0.9f)
            ttsReady = true
        }
    }

    fun playSuccess() {
        scope.launch {
            playTones(listOf(523.25, 659.25, 783.99, 1046.50), durationMs = 80)
        }
    }

    fun playError() {
        scope.launch {
            playTones(listOf(369.99, 293.66, 185.00), durationMs = 120)
        }
    }

    fun playFanfare() {
        scope.launch {
            playTones(listOf(523.25, 659.25, 783.99, 1046.50, 1318.51), durationMs = 100)
        }
    }

    fun playGavel() {
        scope.launch {
            playTones(listOf(220.0, 440.0, 880.0), durationMs = 45)
        }
    }

    fun speak(text: String) {
        if (ttsReady) {
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "LEGAL_FUNDAMENTACION")
        }
    }

    fun stopSpeaking() {
        if (ttsReady) {
            tts?.stop()
        }
    }

    private fun playTones(frequencies: List<Double>, durationMs: Int) {
        val sampleRate = 44100
        val samplesPerTone = (sampleRate * (durationMs / 1000.0)).toInt()
        val totalSamples = samplesPerTone * frequencies.size
        val audioBuffer = ShortArray(totalSamples)

        var sampleIndex = 0
        for (freq in frequencies) {
            for (i in 0 until samplesPerTone) {
                val t = i.toDouble() / sampleRate
                val envelope = sin((i.toDouble() / samplesPerTone) * PI)
                val sample = sin(2 * PI * freq * t) * envelope
                audioBuffer[sampleIndex++] = (sample * 30000).toInt().toShort()
            }
        }

        try {
            val audioTrack = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_GAME)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(audioBuffer.size * 2)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()

            audioTrack.write(audioBuffer, 0, audioBuffer.size)
            audioTrack.play()
            Thread.sleep((durationMs * frequencies.size).toLong() + 40)
            audioTrack.stop()
            audioTrack.release()
        } catch (_: Exception) {}
    }
}
