import '../data/material_catalog.dart';
import '../models/assembly.dart';
import '../models/quiz.dart';

/// Loại liên kết giữa hai vật khi so sánh.
enum ComparisonLink {
  /// Chung vật liệu trực tiếp (vd cùng làm từ nhựa).
  shared,

  /// Không chung trực tiếp nhưng chung NGUỒN GỐC (vd bút chì & giấy đều từ gỗ).
  originOnly,

  /// Hoàn toàn khác nhau.
  none,
}

/// Kết quả so sánh 2 vật theo vật liệu (D8 / TASK-010). Thuần dữ liệu — UI đọc.
class ComparisonResult {
  final String objectA;
  final String objectB;

  /// Vật liệu chung trực tiếp (cả hai cùng được làm từ).
  final List<String> shared;

  /// Nguồn gốc chung sâu hơn (qua chuỗi biến đổi), không tính phần đã chung trực tiếp.
  final List<String> sharedOrigin;

  /// Vật liệu chỉ vật A có / chỉ vật B có.
  final List<String> onlyA;
  final List<String> onlyB;

  const ComparisonResult({
    required this.objectA,
    required this.objectB,
    required this.shared,
    required this.sharedOrigin,
    required this.onlyA,
    required this.onlyB,
  });

  bool get hasShared => shared.isNotEmpty;
  bool get hasOriginLink => sharedOrigin.isNotEmpty;

  ComparisonLink get link => hasShared
      ? ComparisonLink.shared
      : (hasOriginLink ? ComparisonLink.originOnly : ComparisonLink.none);
}

/// Kết quả làm một bộ đố vui sau timeline (TASK-009).
class QuizResult {
  final int correct;
  final int total;

  const QuizResult(this.correct, this.total);

  /// Số sao 1–3 theo tỉ lệ đúng. Hoàn thành luôn được ≥1 sao (không "phạt").
  int get stars =>
      total == 0 ? 0 : (1 + 2 * correct / total).floor().clamp(1, 3);

  double get fraction => total == 0 ? 0 : correct / total;
}

/// Phần thưởng Domain 5 trao cho Domain 3 ghi nhận (contract — ADR-007/008).
class RewardEarned {
  final String kind; // 'quiz_badge' | …
  final String refId; // id đối tượng liên quan (vd object id)

  const RewardEarned({required this.kind, required this.refId});
}

/// Business logic của lớp "Học & Chơi" (Domain 5 — ADR-008). Đọc đồ thị vật liệu
/// qua [MaterialCatalog] (Domain 3, read-only). KHÔNG đặt logic này trong widget
/// (AGENTS.md).
class LearnPlayService {
  final MaterialCatalog _catalog;

  LearnPlayService(this._catalog);

  /// Tiện dùng singleton catalog đã nạp lúc khởi động.
  factory LearnPlayService.fromCatalog() =>
      LearnPlayService(MaterialCatalog.instance);

  /// Tập vật liệu mở rộng của một vật = mọi vật liệu trực tiếp + chuỗi nguồn gốc.
  /// Vd cốc giấy (bột giấy, nhựa) → {gỗ, bột giấy, dầu mỏ, nhựa}.
  Set<String> expandedMaterials(String objectId) {
    final out = <String>{};
    for (final m in _catalog.materialsOf(objectId)) {
      out.addAll(_catalog.derivationChain(m));
    }
    return out;
  }

  /// So sánh hai vật. Phát hiện cả điểm chung trực tiếp lẫn nguồn gốc chung.
  ComparisonResult compare(String a, String b) {
    final directA = _catalog.materialsOf(a).toSet();
    final directB = _catalog.materialsOf(b).toSet();

    final shared = directA.intersection(directB).toList();
    final onlyA = directA.difference(directB).toList();
    final onlyB = directB.difference(directA).toList();

    // Nguồn gốc chung sâu hơn — bỏ phần đã chung trực tiếp để tránh trùng.
    final sharedOrigin = expandedMaterials(a)
        .intersection(expandedMaterials(b))
        .where((m) => !shared.contains(m))
        .toList();

    return ComparisonResult(
      objectA: a,
      objectB: b,
      shared: shared,
      sharedOrigin: sharedOrigin,
      onlyA: onlyA,
      onlyB: onlyB,
    );
  }

  /// Chấm một bộ đố vui theo các đáp án đã chọn (theo chỉ số lựa chọn).
  QuizResult scoreQuiz(List<QuizQuestion> quiz, List<int> answers) {
    var correct = 0;
    for (var i = 0; i < quiz.length && i < answers.length; i++) {
      if (quiz[i].isCorrect(answers[i])) correct++;
    }
    return QuizResult(correct, quiz.length);
  }

  /// Phần thưởng khi hoàn thành đố vui của một vật (trao dù đúng/sai — không phạt).
  RewardEarned quizReward(String objectId) =>
      RewardEarned(kind: 'quiz_badge', refId: objectId);

  // ---- Ghép ngược (TASK-012) ----

  /// Chuỗi node của game ghép: [nguyên liệu đầu, …, vật đích].
  /// Vd bút bi → `[petroleum, plastic, ball_pen]`.
  List<String> assemblyChain(Assembly assembly) {
    final steps = assembly.steps;
    if (steps.isEmpty) return const <String>[];
    return <String>[steps.first.from, for (final s in steps) s.to];
  }

  /// Node cần đặt tiếp theo (ở vị trí [placed]) có đúng là [nodeId] không?
  bool isNextInChain(List<String> chain, int placed, String nodeId) =>
      placed >= 0 && placed < chain.length && chain[placed] == nodeId;

  /// Phần thưởng khi lắp xong một vật.
  RewardEarned assemblyReward(String objectId) =>
      RewardEarned(kind: 'assembly_badge', refId: objectId);
}
