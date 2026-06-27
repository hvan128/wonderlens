package com.wonderlens.wonderlens

import android.graphics.Bitmap
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenter
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors

/**
 * Tách chủ thể khỏi nền bằng ML Kit Subject Segmentation (offline, minSdk 24).
 * Trả PNG nền trong suốt (nguyên khung) qua MethodChannel `wonderlens/segmentation`,
 * hoặc null nếu lỗi/không có chủ thể → Dart rớt về emoji. Mirror của Apple Vision
 * bên iOS (xem `ios/Runner/AppDelegate.swift`).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "wonderlens/segmentation"
    // Giải mã ảnh (InputImage.fromFilePath) là I/O đồng bộ → chạy nền để không
    // chặn main thread (tránh giật khi quét). Listener của ML Kit vẫn về main.
    private val bgExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
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
