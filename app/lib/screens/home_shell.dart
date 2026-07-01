import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/wonder_bottom_nav.dart';

/// Khung "nhà" có bottom-nav (A1 / TASK-021): bọc 2 tab Sân chơi + Bộ sưu tập.
/// Camera (và các màn game/timeline) là route toàn màn hình push **trên** shell —
/// giữ nguyên vòng đời camera (RouteObserver) và cảm giác quét đắm chìm.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: WonderBottomNav(
        currentIndex: navigationShell.currentIndex,
        // Chạm lại tab đang mở → về gốc nhánh đó (initialLocation).
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        // Nút giữa: mở camera toàn màn hình (root route, phủ cả bottom-nav).
        onScan: () => context.push('/camera'),
      ),
    );
  }
}
