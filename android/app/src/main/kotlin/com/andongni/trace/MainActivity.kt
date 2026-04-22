package com.andongni.trace

import android.content.ActivityNotFoundException
import android.content.Intent
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Looper
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.Locale
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val thumbnailExecutor: ExecutorService = Executors.newFixedThreadPool(2)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_OPENER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openMediaFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val mimeType = call.argument<String>("mimeType")
                    result.success(openMediaFile(filePath, mimeType))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MEDIA_THUMBNAILER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "thumbnailForVideo" -> {
                    val videoPath = call.argument<String>("videoPath")
                    thumbnailExecutor.execute {
                        val thumbnailPath = thumbnailForVideo(videoPath)
                        mainHandler.post {
                            result.success(thumbnailPath)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        thumbnailExecutor.shutdown()
        super.onDestroy()
    }

    private fun openMediaFile(filePath: String?, mimeType: String?): Boolean {
        val trimmedPath = filePath?.trim()
        if (trimmedPath.isNullOrEmpty()) {
            return false
        }

        val file = File(trimmedPath)
        if (!file.exists()) {
            return false
        }

        val contentUri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file,
        )
        val resolvedMimeType = mimeType
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: guessMimeType(file)

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(contentUri, resolvedMimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val handlers = packageManager.queryIntentActivities(intent, 0)
        if (handlers.isEmpty()) {
            return false
        }

        for (handler in handlers) {
            grantUriPermission(
                handler.activityInfo.packageName,
                contentUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        }

        return try {
            val chooser = Intent.createChooser(intent, null).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(chooser)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun guessMimeType(file: File): String {
        val extension = file.extension.lowercase(Locale.US)
        if (extension.isEmpty()) {
            return "*/*"
        }
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension) ?: "*/*"
    }

    private fun thumbnailForVideo(videoPath: String?): String? {
        val trimmedPath = videoPath?.trim()
        if (trimmedPath.isNullOrEmpty()) {
            return null
        }

        val videoFile = File(trimmedPath)
        if (!videoFile.exists()) {
            return null
        }

        val thumbnailDirectory = File(cacheDir, "media_video_thumbnails")
        if (!thumbnailDirectory.exists()) {
            thumbnailDirectory.mkdirs()
        }
        val thumbnailFile = File(
            thumbnailDirectory,
            "${sha256("${videoFile.absolutePath}:${videoFile.lastModified()}")}.jpg",
        )
        if (thumbnailFile.exists()) {
            return thumbnailFile.absolutePath
        }

        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoFile.absolutePath)
            val bitmap = retriever.getFrameAtTime(
                0,
                MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
            ) ?: retriever.getFrameAtTime() ?: return null

            FileOutputStream(thumbnailFile).use { stream ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, 86, stream)
            }
            thumbnailFile.absolutePath
        } catch (_: Throwable) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun sha256(value: String): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(value.toByteArray())
        return digest.joinToString("") { byte -> "%02x".format(byte) }
    }

    companion object {
        private const val MEDIA_OPENER_CHANNEL = "trace/media_opener"
        private const val MEDIA_THUMBNAILER_CHANNEL = "trace/media_thumbnailer"
    }
}
