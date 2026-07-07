import 'package:flutter/material.dart';

import '../ui/ui.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Khung chính với **thanh tab NATIVE của iOS** (UITabBar — Liquid Glass + chỉ
/// báo chọn morph "giọt nước" của iOS 26). 3 mục: Trang chủ · Rương · Hồ sơ.
/// Nền chấm dùng chung cho cả 3 tab; camera/timeline push ĐÈ lên (phủ tab bar).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  void _go(int i) {
    if (i != _tab) {
      WonderHaptics.selection();
      setState(() => _tab = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: WonderBackground(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IndexedStack(
                index: _tab,
                children: const <Widget>[
                  HomeScreen(),
                  CollectionScreen(inShell: true),
                  ProfileScreen(),
                ],
              ),
            ),
            // Thanh tab native full-width ở đáy (tự khoác Liquid Glass trên iOS 26).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 49 + safeBottom,
              child: NativeTabBar(index: _tab, onSelect: _go),
            ),
          ],
        ),
      ),
    );
  }
}
