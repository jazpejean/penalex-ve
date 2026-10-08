package com.penalex.ve

import android.content.ContentResolver
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "penalex/uri_resolver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copyToCache" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString == null) {
                            result.error("NO_URI", "Missing 'uri' argument", null)
                        } else {
                            try {
                                result.success(copyUriToCache(Uri.parse(uriString)))
                            } catch (e: Exception) {
                                result.error("COPY_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun copyUriToCache(uri: Uri): String {
        val resolver: ContentResolver = contentResolver
        val file = File.createTempFile("scan_", ".jpg", cacheDir)
        val input = resolver.openInputStream(uri)
            ?: throw Exception("No se pudo abrir el URI: $uri")
        input.use { inStream ->
            FileOutputStream(file).use { outStream ->
                inStream.copyTo(outStream)
                outStream.flush()
            }
        }
        if (file.length() == 0L) {
            throw Exception("Copia vacía para el URI: $uri")
        }
        return file.absolutePath
    }
}
