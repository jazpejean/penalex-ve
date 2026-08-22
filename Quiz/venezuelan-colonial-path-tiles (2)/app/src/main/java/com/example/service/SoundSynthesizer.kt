package com.example.service

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlin.math.PI
import kotlin.math.sin

object SoundSynthesizer {
    private val scope = CoroutineScope(Dispatchers.Default)

    fun playSuccess() {
        scope.launch {
            // Acorde triunfal ascendente: Do5 (523Hz), Mi5 (659Hz), Sol5 (784Hz), Do6 (1046Hz)
            playTones(listOf(523.25, 659.25, 783.99, 1046.50), durationMs = 80)
        }
    }

    fun playError() {
        scope.launch {
            // Tono descendente solemne de fallo
            playTones(listOf(369.99, 293.66, 185.00), durationMs = 120)
        }
    }

    fun playGavel() {
        scope.launch {
            // Golpe de mazo judicial (gavel)
            playTones(listOf(220.0, 440.0, 880.0), durationMs = 40)
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
                // Aplicar envolvente senoidal para evitar clicks al inicio y final
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
            Thread.sleep((durationMs * frequencies.size).toLong() + 50)
            audioTrack.stop()
            audioTrack.release()
        } catch (_: Exception) {
            // Manejo silencioso si el canal de audio está ocupado
        }
    }
}
