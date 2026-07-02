import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/collection_repository.dart';
import '../data/material_catalog.dart';
import '../data/mission_repository.dart';
import '../models/mission.dart';
import '../ui/ui.dart';

/// Màn "Nhiệm vụ" (F-12 / TASK-011 / Domain 3): danh sách nhiệm vụ + tiến độ.
///
/// Tiến độ tính trực tiếp từ bộ sưu tập + thẻ vật liệu đã mở (luôn cập nhật khi
/// khám phá vật mới). Khi mở màn, nhiệm vụ vừa đủ điều kiện → confetti + ghi nhận
/// huy hiệu (dedup, persist qua Hive `wonderlens_progress`).
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  late final ConfettiController _confetti;
  // Guard: catalog nạp lúc khởi động (main) — nếu vào màn quá sớm thì chưa sẵn
  // sàng; hiện trạng thái chờ thay vì crash (StateError từ `instance`).
  bool _ready = false;
  List<Mission> _missions = const <Mission>[];
  Set<String> _discovered = const <String>{};
  Set<String> _unlocked = const <String>{};
  Set<String> _completed = const <String>{};

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _ready = MaterialCatalog.isReady;
    if (!_ready) return;
    final repo = MissionRepository();
    final catalog = MaterialCatalog.instance;
    _discovered = CollectionRepository().discoveredIds().toSet();
    _unlocked = catalog.unlockedCards(_discovered);
    final newly = repo.syncCompletions(
      discovered: _discovered,
      unlockedCards: _unlocked,
      catalog: catalog,
    );
    _missions = repo.missions;
    _completed = repo.completedIds();
    if (newly.isNotEmpty) {
      _confetti.play();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _missions.where((m) => _completed.contains(m.id)).length;

    return WonderScaffold(
      header: WonderHeader(
        title: 'Nhiệm vụ',
        subtitle: _ready
            ? 'Hoàn thành $doneCount/${_missions.length}'
            : 'Đang chuẩn bị…',
        showBack: true,
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/collection'),
      ),
      overlay: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 18,
          gravity: 0.25,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_ready) return const _CatalogWaiting();
    if (_missions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          const SizedBox(height: WonderTokens.space16),
          const _EmptyMissions()
              .animate()
              .fadeIn(duration: WonderTokens.durBase)
              .slideY(begin: 0.1, end: 0),
        ],
      );
    }
    final catalog = MaterialCatalog.instance;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: <Widget>[
        for (var i = 0; i < _missions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: WonderTokens.space12),
            child: _MissionCard(
              mission: _missions[i],
              progress: MissionRepository.progressOf(
                _missions[i],
                discovered: _discovered,
                unlockedCards: _unlocked,
                catalog: catalog,
              ),
              completed: _completed.contains(_missions[i].id),
            )
                .animate(delay: (i * 60).ms)
                .fadeIn(duration: WonderTokens.durBase)
                .slideY(begin: 0.1, end: 0),
          ),
      ],
    );
  }
}

/// Trạng thái chờ nhẹ nhàng khi [MaterialCatalog] chưa nạp xong: spinner brand
/// + một câu trấn an — tránh màn trắng hay crash khi vào quá sớm.
class _CatalogWaiting extends StatelessWidget {
  const _CatalogWaiting();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: WonderTokens.space32),
        child: GlassSurface(
          tone: GlassTone.light,
          padding: const EdgeInsets.all(WonderTokens.space24),
          shadows: WonderShadows.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: WonderColors.wonder,
                ),
              ),
              const SizedBox(height: WonderTokens.space16),
              Text(
                'Tia đang chuẩn bị nhiệm vụ…',
                textAlign: TextAlign.center,
                style: WonderType.body(
                  color: WonderColors.textSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: WonderTokens.durBase),
    );
  }
}

/// Trạng thái rỗng: chưa có nhiệm vụ nào — Tia trấn an thay vì danh sách trống.
class _EmptyMissions extends StatelessWidget {
  const _EmptyMissions();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      shadows: WonderShadows.card,
      child: Column(
        children: <Widget>[
          const TiaMascot(size: 76)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                  begin: -4, end: 4, duration: 2400.ms, curve: Curves.easeInOut),
          const SizedBox(height: WonderTokens.space12),
          Text(
            'Chưa có nhiệm vụ nào!',
            style: WonderType.display(
              color: WonderColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WonderTokens.space8),
          Text(
            'Tia đang chuẩn bị thử thách mới. Bạn cứ đi khám phá đồ vật trước nhé!',
            textAlign: TextAlign.center,
            style: WonderType.body(
              color: WonderColors.textSoft,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Mission mission;
  final MissionProgress progress;
  final bool completed;

  const _MissionCard({
    required this.mission,
    required this.progress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    // Điểm nhấn nhỏ: hoàn thành → hổ phách honey (đậm, rõ trên trắng);
    // đang làm → tím thương hiệu. Bề mặt thẻ luôn trắng glass, không tint.
    final accent = completed ? WonderColors.honey : WonderColors.wonder;
    final Widget card = GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.all(WonderTokens.space16),
      shadows: WonderShadows.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Nền accent rất nhạt + viền accent rõ — emoji là nội dung chính.
                  color: accent.withValues(alpha: 0.14),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Center(
                  child: Text(mission.emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: WonderTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mission.title,
                      style: WonderType.display(
                        color: WonderColors.textStrong,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: WonderTokens.space2),
                    Text(
                      _subtitle(),
                      style: WonderType.body(
                        color: WonderColors.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (completed)
                const PhosphorIcon(
                  PhosphorIconsFill.checkCircle,
                  size: 26,
                  color: WonderColors.honey,
                ),
            ],
          ),
          const SizedBox(height: WonderTokens.space12),
          // Mọi thẻ dùng gradient mặc định mint→spark trên track tím nhạt —
          // luôn đọc rõ trên nền thẻ trắng, tránh vàng-trên-vàng vô hình.
          WonderProgressBar(
            value: progress.fraction,
            height: 12,
          ),
          const SizedBox(height: WonderTokens.space8),
          Text(
            completed
                ? 'Đã mở: ${mission.rewardBadge} 🏅'
                : 'Tiến độ ${progress.current}/${progress.target}',
            style: WonderType.body(
              color:
                  completed ? WonderColors.textStrong : WonderColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    // Thẻ hoàn thành: bề mặt vẫn trắng, chỉ thêm viền mảnh honey phủ ngoài
    // (GlassSurface không nhận màu viền nên vẽ đè bằng foregroundDecoration).
    if (!completed) return card;
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(WonderTokens.radiusLg),
        border: Border.all(
          color: WonderColors.honey.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: card,
    );
  }

  String _subtitle() {
    final goal = mission.goal;
    switch (goal.type) {
      case MissionType.materialCount:
        final what = goal.category ?? goal.material ?? 'vật liệu';
        return 'Tìm ${goal.count} vật làm từ $what';
      case MissionType.discoverSet:
        return 'Khám phá đủ ${goal.objectIds.length} vật trong bộ';
      case MissionType.collectCard:
        return 'Mở ${goal.materialIds.length} thẻ vật liệu';
      case MissionType.unknown:
        return '';
    }
  }
}
