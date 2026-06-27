package com.wonderlens.wonderlens

import android.graphics.Bitmap
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Tách chủ thể khỏi nền bằng ML Kit Subject Segmentation (offline, minSdk 24).
 * Trả PNG nền trong suốt (nguyên khung) qua MethodChannel `wonderlens/segmentation`,
 * hoặc null nếu lỗi/không có chủ thể → Dart rớt về emoji. Mirror của Apple Vision
 * bên iOS (xem `ios/Runner/AppDelegate.swift`).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "wonderlens/segmentation"

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
        try {
            val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
            val options = SubjectSegmenterOptions.Builder()
                .enableForegroundBitmap()
                .build()
            val segmenter = SubjectSegmentation.getClient(options)
            segmenter.process(image)
                .addOnSuccessListener { segResult ->
                    val foreground: Bitmap? = segResult.foregroundBitmap
                    val png = foreground?.let { toPng(it) }
                    segmenter.close()
                    result.success(png)
                }
                .addOnFailureListener {
                    segmenter.close()
                    result.success(null)
                }
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun toPng(bitmap: Bitmap): ByteArray {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
