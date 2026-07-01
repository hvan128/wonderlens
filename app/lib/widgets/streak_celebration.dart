import 'package:flutter/material.dart';

import '../data/streak_repository.dart';
import '../ui/ui.dart';

/// Màn chúc mừng "Chuỗi N ngày! 🔥" (D2 / TASK-020). Hiện khi chuỗi vừa tăng sang
/// ngày mới — nhẹ nhàng, tắt được ngay, không chặn luồng khám phá.
Future<void> showStreakCelebration(BuildContext context, StreakResult result) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _StreakCelebrationDialog(result: result),
  );
}

class _StreakCelebrationDialog extends StatelessWidget {
  final StreakResult result;
  const _StreakCelebrationDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: WonderGradients.magic,
          borderRadius: BorderRadius.circular(WonderTokens.radiusXl),
          boxShadow: WonderShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TiaMascot(size: 72, tone: TiaTone.light),
            const SizedBox(height: 12),
            Text(
              'Chuỗi ${result.current} ngày! 🔥',
              textAlign: TextAlign.center,
              style: WonderType.display(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.isMilestone
                  ? 'Giỏi quá! Ngọn lửa của Tia đang cháy rực rỡ!'
                  : 'Khám phá mỗi ngày để giữ ngọn lửa của Tia cháy sáng nhé!',
              textAlign: TextAlign.center,
              style: WonderType.body(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _FlameRow(current: result.current),
            const SizedBox(height: 22),
            WonderButton(
              label: 'Tuyệt vời!',
              icon: PhosphorIconsFill.sparkle,
              gradient: WonderGradients.sunny,
              foreground: WonderColors.onSpark,
              glowColor: WonderColors.spark,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hàng "ngọn lửa": ngày đã giữ chuỗi hiện 🔥, vài ngày kế tiếp hiện số mờ.
class _FlameRow extends StatelessWidget {
  final int current;
  const _FlameRow({required this.current});

  @override
  Widget build(BuildContext context) {
    const slots = 5;
    final filled = current.clamp(0, slots);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (var i = 0; i < slots; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 8),
          _DayDot(filled: i < filled, label: i < filled ? '🔥' : '${i + 1}'),
        ],
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool filled;
  final String label;
  const _DayDot({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? WonderColors.spark : Colors.white.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: filled ? 20 : 16,
            fontWeight: FontWeight.w800,
            color: filled ? WonderColors.onSpark : Colors.white,
          ),
        ),
      ),
    );
  }
}
