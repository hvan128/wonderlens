import 'package:flutter/material.dart';

import 'screens/playground_screen.dart';
import 'theme/app_theme.dart';

/// Entry dev-only để xem nhanh design system v2 mà không phải đi qua
/// gesture ẩn (long-press logo → Dev panel):
///
///   flutter run -t lib/main_playground.dart
///
/// Không dùng cho build phát hành.
void main() {
  runApp(const _PlaygroundApp());
}

class _PlaygroundApp extends StatelessWidget {
  const _PlaygroundApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const PlaygroundScreen(),
    );
  }
}
