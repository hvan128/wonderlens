import '../data/collection_repository.dart';
import 'object_content.dart';

/// Gói dữ liệu đi xuyên luồng video: Camera → Confirm → Generating → Video →
/// Share → Badge. Truyền qua `GoRouterState.extra` để các màn không phải tự tra
/// lại nội dung/độ tin cậy/kết quả ghi nhận.
class JourneyArgs {
  final ObjectContent content;

  /// Nhận diện chắc chắn (≥ ngưỡng) hay còn ngờ ngợ.
  final bool confident;

  /// Độ tin cậy 0..1 để hiển thị (vd "95%"). Null nếu không có.
  final double? confidence;

  /// Kết quả ghi nhận bộ sưu tập (gán sau khi "dựng phim" ở màn Generating).
  final DiscoveryResult? result;

  const JourneyArgs({
    required this.content,
    this.confident = true,
    this.confidence,
    this.result,
  });

  JourneyArgs withResult(DiscoveryResult result) => JourneyArgs(
        content: content,
        confident: confident,
        confidence: confidence,
        result: result,
      );

  /// Phần trăm tin cậy đã làm tròn (vd 95). Null nếu không có.
  int? get confidencePct =>
      confidence == null ? null : (confidence! * 100).round();
}
