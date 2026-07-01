import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Thanh điều hướng dưới cùng (A1): Sân chơi · [📷 quét] · Bộ sưu tập.
/// Nút giữa là **hành động** quét (mở camera toàn màn hình), không phải tab.
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
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: Colors.white, width: 1),
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
                  emoji: '🎪',
                  label: 'Sân chơi',
                  active: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              _CenterScan(onTap: onScan),
              Expanded(
                child: _NavItem(
                  emoji: '🗂️',
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
  final String emoji;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.emoji,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            label,
            style: WonderType.body(
              color: active ? WonderColors.wonder : WonderColors.textFaint,
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: WonderGradients.badge,
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
