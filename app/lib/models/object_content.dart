import 'assembly.dart';
import 'quiz.dart';

/// Một chặng trong "hành trình tạo ra vật".
class Stage {
  final String title;
  final String? illustration; // tên asset hoặc URL
  final String kidText;
  final String? funFact;
  final String? audio; // tên asset hoặc URL audio narration

  const Stage({
    required this.title,
    this.illustration,
    required this.kidText,
    this.funFact,
    this.audio,
  });

  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
        title: (json['title'] ?? '') as String,
        illustration: json['illustration'] as String?,
        kidText: (json['kid_text'] ?? '') as String,
        funFact: json['fun_fact'] as String?,
        audio: json['audio'] as String?,
      );
}

/// Nội dung đầy đủ của một vật: dùng chung cho nguồn curated (asset) và AI live.
class ObjectContent {
  final String id;
  final String name;
  final String emoji;
  final String materialBadge;
  final List<Stage> stages;
  final String source; // 'asset' | 'live' | 'mock'
  final String? video; // asset path video hành trình đóng gói sẵn (vật hero)
  final String? history; // lịch sử ngắn của vật/vật liệu
  final String? story; // câu chuyện hoàn chỉnh — dùng làm audio chính
  final List<String> materials; // id thẻ vật liệu (ADR-012); optional
  final List<QuizQuestion> quiz; // đố vui sau timeline (TASK-018); optional
  final Assembly? assembly; // game ghép ngược (TASK-018); optional

  const ObjectContent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.materialBadge,
    required this.stages,
    this.source = 'asset',
    this.video,
    this.history,
    this.story,
    this.materials = const <String>[],
    this.quiz = const <QuizQuestion>[],
    this.assembly,
  });

  /// Văn bản đọc to chính cho trang chi tiết: ưu tiên [story] (câu chuyện hoàn
  /// chỉnh). Nếu chưa có thì ghép lịch sử + các chặng để vẫn luôn có audio.
  String get narrationText {
    final s = story?.trim() ?? '';
    if (s.isNotEmpty) return s;
    final parts = <String>[];
    final h = history?.trim() ?? '';
    if (h.isNotEmpty) parts.add(h);
    for (final st in stages) {
      if (st.kidText.isNotEmpty) parts.add(st.kidText);
      final f = st.funFact;
      if (f != null && f.isNotEmpty) parts.add(f);
    }
    return parts.join(' ');
  }

  factory ObjectContent.fromJson(
    Map<String, dynamic> json, {
    String source = 'asset',
  }) =>
      ObjectContent(
        id: (json['id'] ?? 'unknown') as String,
        name: (json['name'] ?? 'Vật bí ẩn') as String,
        emoji: (json['emoji'] ?? '✨') as String,
        materialBadge: (json['material_badge'] ?? '') as String,
        stages: ((json['stages'] as List?) ?? const [])
            .map((e) => Stage.fromJson(e as Map<String, dynamic>))
            .toList(),
        source: source,
        video: json['video'] as String?,
        history: json['history'] as String?,
        story: json['story'] as String?,
        materials: ((json['materials'] as List?) ?? const <dynamic>[])
            .map((e) => e as String)
            .toList(),
        quiz: ((json['quiz'] as List?) ?? const <dynamic>[])
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .where((q) => q.isValid)
            .toList(),
        assembly: _assemblyFromJson(json['assembly']),
      );
}

/// Parse [Assembly] an toàn: chỉ trả về khi hợp lệ, ngược lại null (ẩn game).
Assembly? _assemblyFromJson(dynamic raw) {
  if (raw is! Map) return null;
  final a = Assembly.fromJson(Map<String, dynamic>.from(raw));
  return a.isValid ? a : null;
}
