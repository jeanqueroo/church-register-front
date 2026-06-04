package com.church.register.church_registe

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "com.church.register/external_map")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "launchUrl" -> {
                        val url = call.arguments as? String
                        if (url.isNullOrBlank()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            if (intent.resolveActivity(packageManager) != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(messenger, "com.church.register/file_share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareFile" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? Map<String, Any?>
                        val bytes = args?.get("bytes")
                        val fileName = args?.get("fileName") as? String ?: "export.csv"
                        val mimeType = args?.get("mimeType") as? String ?: "text/csv"
                        val subject = args?.get("subject") as? String ?: ""

                        val byteArray = bytes as? ByteArray
                        if (byteArray == null || byteArray.isEmpty()) {
                            result.success(false)
                            return@setMethodCallHandler
                        }

                        try {
                            val shareDir = File(cacheDir, "share")
                            shareDir.mkdirs()
                            val file = File(shareDir, fileName)
                            file.writeBytes(byteArray)

                            val uri = FileProvider.getUriForFile(
                                this,
                                "${applicationContext.packageName}.fileprovider",
                                file,
                            )

                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                putExtra(Intent.EXTRA_SUBJECT, subject)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(Intent.createChooser(intent, subject))
                            result.success(true)
                        } catch (_: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
