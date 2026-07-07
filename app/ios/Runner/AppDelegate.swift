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
    // Liquid Glass native (iOS 26+) cho thanh tab — glass thật của hệ điều hành.
    if let glassRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "WonderLensLiquidGlass")
    {
      glassRegistrar.register(LiquidGlassFactory(), withId: "wonder_liquid_glass")
    }
    // Thanh tab NATIVE của iOS (UITabBar) — có Liquid Glass + chỉ báo chọn morph
    // "giọt nước" mượt của iOS 26. Sự kiện chọn tab gửi về Flutter qua channel.
    if let tabRegistrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "WonderLensTabBar")
    {
      tabRegistrar.register(
        NativeTabBarFactory(messenger: tabRegistrar.messenger()),
        withId: "wonder_native_tabbar")
    }
  }
}

/// PlatformView bọc **UITabBar native**. iOS 26 tự khoác Liquid Glass + hiệu ứng
/// chọn tab morph mượt. Chạm tab → gửi index về Flutter qua `wonderlens/tabbar`;
/// Flutter có thể set lại index bằng `setIndex`.
final class NativeTabBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NativeTabBarView(frame: frame, messenger: messenger, args: args)
  }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class NativeTabBarView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let bar = UITabBar()
  private let channel: FlutterMethodChannel

  init(frame: CGRect, messenger: FlutterBinaryMessenger, args: Any?) {
    channel = FlutterMethodChannel(name: "wonderlens/tabbar", binaryMessenger: messenger)
    super.init()
    let dict = args as? [String: Any]
    let labels = (dict?["labels"] as? [String]) ?? ["Trang chủ", "Rương", "Hồ sơ"]
    let iconData = dict?["icons"] as? [FlutterStandardTypedData]
    let fallback = ["house.fill", "square.grid.2x2.fill", "person.fill"]
    // Icon lấy từ app (render sẵn bên Flutter) → template để native tự tô màu
    // theo trạng thái chọn; thiếu thì rớt về SF Symbol.
    let items: [UITabBarItem] = (0..<3).map { i in
      var image: UIImage?
      if let d = iconData, i < d.count {
        // scale 3.0: PNG render ở pixel → coi là @3x (≈28pt) cho đúng cỡ tab bar
        // (mặc định scale 1.0 sẽ coi px = pt → icon khổng lồ).
        image = UIImage(data: d[i].data, scale: 3.0)?
          .withRenderingMode(.alwaysTemplate)
      }
      if image == nil { image = UIImage(systemName: fallback[i]) }
      let title = i < labels.count ? labels[i] : ""
      return UITabBarItem(title: title, image: image, tag: i)
    }
    bar.setItems(items, animated: false)
    var initial = 0
    if let idx = dict?["index"] as? Int { initial = idx }
    bar.selectedItem = items[min(max(initial, 0), items.count - 1)]
    bar.delegate = self
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      if call.method == "setIndex",
        let i = call.arguments as? Int,
        let items = self.bar.items, i >= 0, i < items.count
      {
        self.bar.selectedItem = items[i]
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { bar }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    channel.invokeMethod("onSelect", arguments: item.tag)
  }
}

/// PlatformView: nền **Liquid Glass native của iOS 26** (`UIGlassEffect`), rớt
/// về material blur trên iOS cũ. Không nhận chạm (các nút tab là widget Flutter
/// phủ lên trên). Tự bo capsule theo chiều cao.
final class LiquidGlassFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassPlatformView(frame: frame)
  }
}

final class LiquidGlassPlatformView: NSObject, FlutterPlatformView {
  private let capsule: GlassCapsuleView
  init(frame: CGRect) {
    capsule = GlassCapsuleView(frame: frame)
    super.init()
  }
  func view() -> UIView { capsule }
}

final class GlassCapsuleView: UIView {
  private let effectView: UIVisualEffectView

  override init(frame: CGRect) {
    if #available(iOS 26.0, *) {
      effectView = UIVisualEffectView(effect: UIGlassEffect())
    } else {
      effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    }
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    effectView.clipsToBounds = true
    effectView.layer.cornerCurve = .continuous
    addSubview(effectView)
  }

  required init?(coder: NSCoder) { fatalError("not implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    effectView.frame = bounds
    effectView.layer.cornerRadius = min(bounds.width, bounds.height) / 2.0
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
      // croppedToInstancesExtent: FALSE → foreground giữ NGUYÊN khung ảnh gốc
      // (nền trong suốt) thay vì cắt sát bbox chủ thể. Bắt buộc để mask khớp toạ
      // độ với ảnh JPEG khi hiệu ứng tan biến phủ mask lên toàn khung; bên Dart
      // `tightCropTransparentPng` vẫn tự cắt sát khi cần sticker bộ sưu tập.
      let maskedBuffer = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: false)
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
