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
  late final List<Mission> _missions;
  late final Set<String> _discovered;
  late final Set<String> _unlocked;
  late final Set<String> _completed;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
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
    final catalog = MaterialCatalog.instance;
    final doneCount = _missions.where((m) => _completed.contains(m.id)).length;

    return WonderScaffold(
      header: WonderHeader(
        title: 'Nhiệm vụ',
        subtitle: 'Hoàn thành $doneCount/${_missions.length}',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          for (var i = 0; i < _missions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
    final accent = completed ? WonderColors.sunny : WonderColors.teal;
    return GlassSurface(
      tone: GlassTone.light,
      padding: const EdgeInsets.all(16),
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
                  color: accent.withValues(alpha: 0.16),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(mission.emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mission.title,
                      style: const TextStyle(
                        color: WonderColors.textStrong,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitle(),
                      style: TextStyle(
                        color: WonderColors.textSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (completed)
                const PhosphorIcon(
                  PhosphorIconsFill.sealCheck,
                  size: 26,
                  color: Color(0xFFE08A00),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _Bar(fraction: progress.fraction, accent: accent),
          const SizedBox(height: 8),
          Text(
            completed
                ? 'Đã mở: ${mission.rewardBadge} 🏅'
                : 'Tiến độ ${progress.current}/${progress.target}',
            style: TextStyle(
              color:
                  completed ? WonderColors.textStrong : WonderColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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

class _Bar extends StatelessWidget {
  final double fraction;
  final Color accent;
  const _Bar({required this.fraction, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WonderTokens.pill),
      child: Stack(
        children: <Widget>[
          Container(height: 12, color: accent.withValues(alpha: 0.14)),
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(WonderTokens.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
