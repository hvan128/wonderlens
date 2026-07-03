import 'package:flutter/material.dart';

import '../theme/wonder_tokens.dart';
import '../theme/wonder_typography.dart';
import 'phosphor_compat.dart';
import 'pressable.dart';

/// Thanh điều hướng dưới cùng (A1): Sân chơi · [📷 quét] · Bộ sưu tập.
/// Nút giữa là **hành động** quét (mở camera toàn màn hình), không phải tab.
/// Tab active có pill oải hương + icon đổi màu (học Duolingo — trạng thái rõ).
class WonderBottomNav extends StatelessWidget {
  final int currentIndex; // 0 = Sân chơi, 1 = Bộ sưu tập
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  const WonderBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: WonderColors.wonderSoft, width: 1.5),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: WonderColors.wonderDeep.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _NavItem(
                  icon: PhosphorIconsFill.gameController,
                  label: 'Sân chơi',
                  active: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              _CenterScan(onTap: onScan),
              Expanded(
                child: _NavItem(
                  icon: PhosphorIconsFill.backpack,
                  label: 'Bộ sưu tập',
                  active: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? WonderColors.wonder : WonderColors.textFaint;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Pill nền oải hương trượt vào khi tab active.
          AnimatedContainer(
            duration: WonderTokens.durBase,
            curve: WonderTokens.curveStandard,
            padding: const EdgeInsets.symmetric(
              horizontal: WonderTokens.space16,
              vertical: WonderTokens.space4,
            ),
            decoration: BoxDecoration(
              color: active ? WonderColors.wonderSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(WonderTokens.pill),
            ),
            child: PhosphorIcon(icon, size: 24, color: color),
          ),
          const SizedBox(height: WonderTokens.space2),
          Text(
            label,
            style: WonderType.body(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterScan extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterScan({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Quét đồ vật',
      child: Transform.translate(
        offset: const Offset(0, -8),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: WonderGradients.badge,
            // Viền trắng tách nút khỏi thanh nav — nút giữa nổi hẳn lên.
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: WonderShadows.glow(WonderColors.wonder, opacity: 0.5),
          ),
          child: const Center(
            child: PhosphorIcon(
              PhosphorIconsBold.camera,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
