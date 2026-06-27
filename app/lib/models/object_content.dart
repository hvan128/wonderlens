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

  const ObjectContent({
    required this.id,
    required this.name,
    required this.emoji,
    required this.materialBadge,
    required this.stages,
    this.source = 'asset',
  });

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
      );
}
