package com.wonderlens.wonderlens

import android.content.ContentValues
import android.graphics.Bitmap
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenter
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * Tách chủ thể khỏi nền bằng ML Kit Subject Segmentation (offline, minSdk 24).
 * Trả PNG nền trong suốt (nguyên khung) qua MethodChannel `wonderlens/segmentation`,
 * hoặc null nếu lỗi/không có chủ thể → Dart rớt về emoji. Mirror của Apple Vision
 * bên iOS (xem `ios/Runner/AppDelegate.swift`).
 */
class MainActivity : FlutterActivity() {
    private val segmentationChannelName = "wonderlens/segmentation"
    private val photoLibraryChannelName = "wonderlens/photo_library"
    // Giải mã ảnh (InputImage.fromFilePath) là I/O đồng bộ → chạy nền để không
    // chặn main thread (tránh giật khi quét). Listener của ML Kit vẫn về main.
    private val bgExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, segmentationChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "cutout") {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(null)
                    } else {
                        cutout(path, result)
                    }
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, photoLibraryChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveImage") {
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name") ?: "wonderlens_sticker.png"
                    val album = call.argument<String>("album") ?: "WonderLens"
                    if (path == null) {
                        result.success(false)
                    } else {
                        saveImage(path, name, album, result)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveImage(
        path: String,
        fileName: String,
        album: String,
        result: MethodChannel.Result
    ) {
        bgExecutor.execute {
            val source = File(path)
            if (!source.exists()) {
                runOnUiThread { result.success(false) }
                return@execute
            }
            try {
                val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    saveImageWithMediaStore(source, fileName, album)
                } else {
                    saveImageLegacy(source, fileName, album)
                }
                runOnUiThread { result.success(ok) }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("save_failed", e.localizedMessage, null)
                }
            }
        }
    }

    private fun saveImageWithMediaStore(source: File, fileName: String, album: String): Boolean {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$album")
            put(MediaStore.Images.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            ?: return false
        try {
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(source).use { input -> input.copyTo(out) }
            } ?: return false
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return true
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    private fun saveImageLegacy(source: File, fileName: String, album: String): Boolean {
        val dir = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), album)
        if (!dir.exists() && !dir.mkdirs()) return false
        val target = File(dir, fileName)
        FileInputStream(source).use { input ->
            FileOutputStream(target).use { out -> input.copyTo(out) }
        }
        MediaScannerConnection.scanFile(
            this,
            arrayOf(target.absolutePath),
            arrayOf("image/png"),
            null
        )
        return true
    }

    private fun cutout(path: String, result: MethodChannel.Result) {
        bgExecutor.execute {
            val image = try {
                InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            } catch (e: Exception) {
                runOnUiThread { result.success(null) }
                return@execute
            }
            val segmenter = SubjectSegmentation.getClient(
                SubjectSegmenterOptions.Builder().enableForegroundBitmap().build()
            )
            // addOnSuccessListener/addOnFailureListener (không truyền executor) chạy
            // trên main thread → result.success gọi đúng luồng, đúng một lần.
            segmenter.process(image)
                .addOnSuccessListener { segResult ->
                    val png = try {
                        segResult.foregroundBitmap?.let { toPng(it) }
                    } catch (e: Exception) {
                        null
                    }
                    closeQuietly(segmenter)
                    result.success(png)
                }
                .addOnFailureListener {
                    closeQuietly(segmenter)
                    result.success(null)
                }
        }
    }

    private fun closeQuietly(segmenter: SubjectSegmenter) {
        try {
            segmenter.close()
        } catch (e: Exception) {
            // Bỏ qua — đảm bảo result luôn được trả về.
        }
    }

    private fun toPng(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
