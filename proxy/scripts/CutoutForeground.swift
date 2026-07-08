// Tách chủ thể khỏi nền bằng Apple Vision (macOS 14+) — sinh PNG trong suốt
// CÙNG khung hình với ảnh gốc, để lớp phủ trong app khớp pixel tuyệt đối.
// Dùng cho ảnh onboarding (không gọi API — offline, miễn phí, tất định):
//   swift scripts/CutoutForeground.swift <ảnh vào> <png ra>
import Vision
import CoreImage
import Foundation

guard CommandLine.arguments.count == 3 else {
    print("usage: swift CutoutForeground.swift <input> <output.png>")
    exit(2)
}
let inURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outURL = URL(fileURLWithPath: CommandLine.arguments[2])

let handler = VNImageRequestHandler(url: inURL)
let request = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([request])
guard let result = request.results?.first else {
    print("Vision không tìm thấy chủ thể nào trong \(inURL.path)")
    exit(1)
}
let buffer = try result.generateMaskedImage(
    ofInstances: result.allInstances,
    from: handler,
    croppedToInstancesExtent: false
)
let image = CIImage(cvPixelBuffer: buffer)
let context = CIContext()
try context.writePNGRepresentation(
    of: image,
    to: outURL,
    format: .RGBA8,
    colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
)
print("saved \(outURL.path)")
