/// Câu đố "đoán trước" trong content cũ (ADR-008). Timeline hiện tại không
/// render field này thành cổng chặn; parse hỏng/thiếu → null, không crash.
class StagePredict {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String? hint; // gợi ý khi đoán sai (không phạt)

  const StagePredict({
    required this.question,
    required this.options,
    required this.answerIndex,
    this.hint,
  });

  static StagePredict? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final question = (json['question'] ?? '') as String;
    final options = ((json['options'] as List?) ?? const [])
        .whereType<String>()
        .where((o) => o.trim().isNotEmpty)
        .toList();
    final answerIndex = json['answer_index'];
    if (question.trim().isEmpty ||
        options.length < 2 ||
        answerIndex is! int ||
        answerIndex < 0 ||
        answerIndex >= options.length) {
      return null;
    }
    return StagePredict(
      question: question,
      options: options,
      answerIndex: answerIndex,
      hint: json['hint'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'answer_index': answerIndex,
    if (hint != null) 'hint': hint,
  };
}

/// Hành động "vận hành" một chặng (dữ liệu content, parse giữ nguyên).
/// UI KHÔNG còn render cổng này — amendment ADR-008: gesture chặn đường gây
/// ma sát kép với câu đố dự đoán; cổng giữa các chặng giờ chỉ còn `predict`.
class StageAction {
  static const types = {'hold', 'swipe', 'tap', 'drag'};

  final String type; // hold | swipe | tap | drag
  final String label;

  const StageAction({required this.type, required this.label});

  static StageAction? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final type = (json['type'] ?? '') as String;
    final label = (json['label'] ?? '') as String;
    if (label.trim().isEmpty || !types.contains(type)) return null;
    return StageAction(type: type, label: label);
  }

  Map<String, dynamic> toJson() => {'type': type, 'label': label};
}

/// Thí nghiệm mini với vật thật trong content cũ. Timeline hiện tại không render
/// field này thành bước bắt buộc; thiếu/hỏng → null.
class HomeExperiment {
  final String title;
  final String prompt;
  final String? reveal; // giải thích hiện sau khi bé xác nhận đã làm
  final String? badge; // tên badge phụ (ví dụ "Nhà khoa học nhí")

  const HomeExperiment({
    required this.title,
    required this.prompt,
    this.reveal,
    this.badge,
  });

  static HomeExperiment? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final prompt = (json['prompt'] ?? '') as String;
    if (prompt.trim().isEmpty) return null;
    final title = (json['title'] ?? '') as String;
    return HomeExperiment(
      title: title.trim().isEmpty ? 'Nhiệm vụ mini tại nhà' : title,
      prompt: prompt,
      reveal: json['reveal'] as String?,
      badge: json['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'prompt': prompt,
    if (reveal != null) 'reveal': reveal,
    if (badge != null) 'badge': badge,
  };
}

/// Một chặng trong "hành trình tạo ra vật".
class Stage {
  final String title;
  final String? illustration; // tên asset hoặc URL
  final String kidText;
  final String? funFact;
  final String? audio; // tên asset hoặc URL audio narration
  final StagePredict? predict; // dữ liệu cũ; UI timeline không render gate
  final StageAction?
  action; // dữ liệu "vận hành" — UI không dùng (ADR-008 amend)

  const Stage({
    required this.title,
    this.illustration,
    required this.kidText,
    this.funFact,
    this.audio,
    this.predict,
    this.action,
  });

  factory Stage.fromJson(Map<String, dynamic> json) => Stage(
    title: (json['title'] ?? '') as String,
    illustration: json['illustration'] as String?,
    kidText: (json['kid_text'] ?? '') as String,
    funFact: json['fun_fact'] as String?,
    audio: json['audio'] as String?,
    predict: StagePredict.fromJson(json['predict']),
    action: StageAction.fromJson(json['action']),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    if (illustration != null) 'illustration': illustration,
    'kid_text': kidText,
    if (funFact != null) 'fun_fact': funFact,
    if (audio != null) 'audio': audio,
    if (predict != null) 'predict': predict!.toJson(),
    if (action != null) 'action': action!.toJson(),
  };
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
  final HomeExperiment? experiment; // dữ liệu cũ; UI timeline không render gate

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
    this.experiment,
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
  }) => ObjectContent(
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
    experiment: HomeExperiment.fromJson(json['experiment']),
  );

  /// Round-trip với [ObjectContent.fromJson] (`source` truyền lại khi đọc).
  /// Dùng để lưu vật AI-live vào nhật ký khám phá → mở lại offline.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'material_badge': materialBadge,
    'stages': [for (final s in stages) s.toJson()],
    if (video != null) 'video': video,
    if (history != null) 'history': history,
    if (story != null) 'story': story,
    if (experiment != null) 'experiment': experiment!.toJson(),
  };
}
