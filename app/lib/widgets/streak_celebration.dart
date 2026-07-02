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
          // Mốc chuỗi đặc biệt → viền vàng tia sáng quanh dialog ghi nhận thành tích.
          border: result.isMilestone
              ? Border.all(color: WonderColors.sunny, width: 2)
              : null,
          boxShadow: WonderShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Choreography mở màn: Tia nhún vào → tiêu đề hiện → đốm lửa cháy dần.
            const TiaMascot(size: 72, tone: TiaTone.light).animate().scaleXY(
                  begin: 0.4,
                  end: 1,
                  duration: const Duration(milliseconds: 320),
                  curve: WonderTokens.curveEmphasized,
                ),
            const SizedBox(height: WonderTokens.space12),
            Text(
              'Chuỗi ${result.current} ngày! 🔥',
              textAlign: TextAlign.center,
              style: WonderType.display(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(
                  delay: const Duration(milliseconds: 120),
                  duration: WonderTokens.durBase,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: WonderTokens.space8),
            Text(
              result.isMilestone
                  ? 'Giỏi quá! Ngọn lửa của Tia đang cháy rực rỡ!'
                  : 'Khám phá mỗi ngày để giữ ngọn lửa của Tia cháy sáng nhé!',
              textAlign: TextAlign.center,
              style: WonderType.body(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(
                  delay: const Duration(milliseconds: 200),
                  duration: WonderTokens.durBase,
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: WonderTokens.space20),
            _FlameRow(current: result.current),
            const SizedBox(height: WonderTokens.space24),
            WonderButton(
              label: 'Tuyệt vời!',
              icon: PhosphorIconsFill.sparkle,
              gradient: WonderGradients.sunny,
              foreground: WonderColors.onSpark,
              glowColor: WonderColors.spark,
              onTap: () => Navigator.of(context).pop(),
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 240),
                  duration: WonderTokens.durBase,
                  curve: Curves.easeOut,
                )
                .slideY(begin: 0.15, end: 0),
          ],
        ),
      ),
    );
  }
}

/// Hàng "ngọn lửa": mỗi ngày đã giữ chuỗi là một đốm lửa "bốc cháy" lần lượt
/// (stagger ~90ms/đốm); vài ngày kế tiếp hiện số mờ để bé thấy đích gần kề.
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
          if (i > 0) const SizedBox(width: WonderTokens.space8),
          _DayDot(
            filled: i < filled,
            isCurrent: i == filled - 1,
            dayNumber: i + 1,
          )
              .animate()
              .scaleXY(
                begin: 0.4,
                end: 1,
                delay: Duration(milliseconds: 320 + i * 90),
                duration: WonderTokens.durBase,
                curve: WonderTokens.curveEmphasized,
              )
              // fadeIn kế thừa delay từ scaleXY → đốm "hiện + nở" cùng nhịp.
              .fadeIn(duration: WonderTokens.durFast, curve: Curves.easeOut),
        ],
      ],
    );
  }
}

/// Một ô ngày trong chuỗi: ngày đã giữ lửa → icon lửa trên nền vàng tia sáng;
/// ngày HIỆN TẠI thêm quầng sáng spark; ngày chưa tới → số mờ trên nền kính.
class _DayDot extends StatelessWidget {
  final bool filled;
  final bool isCurrent;
  final int dayNumber;
  const _DayDot({
    required this.filled,
    required this.isCurrent,
    required this.dayNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            filled ? WonderColors.spark : Colors.white.withValues(alpha: 0.18),
        boxShadow: isCurrent ? WonderShadows.glow(WonderColors.spark) : null,
      ),
      child: Center(
        child: filled
            ? const PhosphorIcon(
                PhosphorIconsFill.fire,
                size: 22,
                color: WonderColors.onSpark,
              )
            : Text(
                '$dayNumber',
                style: WonderType.display(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
