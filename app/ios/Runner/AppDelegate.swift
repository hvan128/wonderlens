import AVFoundation
import CoreImage
import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Cho phim hành trình + giọng đọc có tiếng KỂ CẢ khi gạt công tắc im lặng
    // (mặc định video_player theo category bị mute switch tắt → app trẻ em cần nghe).
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WonderLensSegmentation") {
      let channel = FlutterMethodChannel(
        name: "wonderlens/segmentation",
        binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "cutout" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(nil)
          return
        }
        SubjectCutout.run(path: path, result: result)
      }
    }
  }
}

/// Tách chủ thể khỏi nền bằng Apple Vision (iOS 17+). Trả PNG nền trong suốt đã
/// cắt sát chủ thể, hoặc `nil` (iOS < 17 / không có chủ thể / lỗi) để Dart rớt
/// về emoji. Mọi tính toán chạy nền để không chặn UI.
enum SubjectCutout {
  static func run(path: String, result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      result(nil)
      return
    }
    DispatchQueue.global(qos: .userInitiated).async {
      let png = Self.cutoutPng(path: path)
      DispatchQueue.main.async { result(png) }
    }
  }

  @available(iOS 17.0, *)
  private static func cutoutPng(path: String) -> FlutterStandardTypedData? {
    guard
      let original = UIImage(contentsOfFile: path),
      let cgImage = normalizedUp(original).cgImage
    else {
      return nil
    }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
    do {
      try handler.perform([request])
      guard
        let observation = request.results?.first,
        !observation.allInstances.isEmpty
      else {
        return nil
      }
      let maskedBuffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: true)
      return pngData(from: maskedBuffer).map { FlutterStandardTypedData(bytes: $0) }
    } catch {
      NSLog("WonderLens segmentation error: \(error.localizedDescription)")
      return nil
    }
  }

  /// CVPixelBuffer (RGBA, có alpha) → PNG giữ nguyên kênh alpha.
  private static func pngData(from buffer: CVPixelBuffer) -> Data? {
    let ciImage = CIImage(cvPixelBuffer: buffer)
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
      return nil
    }
    return UIImage(cgImage: cgImage).pngData()
  }

  /// Vẽ lại ảnh về orientation `.up` để mask không bị xoay/lệch theo EXIF.
  private static func normalizedUp(_ image: UIImage) -> UIImage {
    if image.imageOrientation == .up { return image }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = image.scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }
}
