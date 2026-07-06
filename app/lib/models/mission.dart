/// Loại mục tiêu nhiệm vụ (D6 / TASK-011). Xem `specs/api-contracts.md`.
enum MissionType {
  /// Đếm số vật đã khám phá thuộc một nhóm/vật liệu.
  materialCount,

  /// Khám phá đủ một bộ vật cụ thể.
  discoverSet,

  /// Mở đủ một bộ thẻ vật liệu.
  collectCard,

  /// Không nhận diện được (mission hỏng) → bị bỏ qua an toàn.
  unknown,
}

class MissionGoal {
  final MissionType type;
  final String? category; // material_count theo nhóm (Giấy/Nhựa/Kim loại/Gỗ…)
  final String? material; // material_count theo 1 thẻ cụ thể (vd 'steel')
  final int count; // material_count
  final List<String> objectIds; // discover_set
  final List<String> materialIds; // collect_card

  const MissionGoal({
    required this.type,
    this.category,
    this.material,
    this.count = 0,
    this.objectIds = const <String>[],
    this.materialIds = const <String>[],
  });

  /// Mốc cần đạt để hoàn thành.
  int get target => switch (type) {
        MissionType.materialCount => count,
        MissionType.discoverSet => objectIds.length,
        MissionType.collectCard => materialIds.length,
        MissionType.unknown => 0,
      };

  factory MissionGoal.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']) {
      'material_count' => MissionType.materialCount,
      'discover_set' => MissionType.discoverSet,
      'collect_card' => MissionType.collectCard,
      _ => MissionType.unknown,
    };
    return MissionGoal(
      type: type,
      category: json['category'] as String?,
      material: json['material'] as String?,
      count: (json['count'] as num?)?.toInt() ?? 0,
      objectIds: ((json['object_ids'] as List?) ?? const <dynamic>[])
          .map((e) => e as String)
          .toList(),
      materialIds: ((json['material_ids'] as List?) ?? const <dynamic>[])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class Mission {
  final String id;
  final String title;
  final String emoji;
  final MissionGoal goal;
  final String rewardBadge;

  const Mission({
    required this.id,
    required this.title,
    required this.emoji,
    required this.goal,
    required this.rewardBadge,
  });

  /// Mission hợp lệ (đủ id + goal nhận diện được + mốc > 0).
  bool get isValid =>
      id.isNotEmpty && goal.type != MissionType.unknown && goal.target > 0;

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        emoji: (json['emoji'] ?? '🎯') as String,
        goal: MissionGoal.fromJson(
          (json['goal'] as Map<String, dynamic>?) ?? const <String, dynamic>{},
        ),
        rewardBadge: (json['reward_badge'] ?? '') as String,
      );
}

/// Tiến độ một nhiệm vụ tại một thời điểm.
class MissionProgress {
  final int current;
  final int target;

  const MissionProgress(this.current, this.target);

  bool get done => target > 0 && current >= target;
  double get fraction => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}
