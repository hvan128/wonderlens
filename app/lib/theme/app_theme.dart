import 'package:flutter/material.dart';

import 'wonder_tokens.dart';
import 'wonder_typography.dart';

/// Theme trẻ em v2: tông **tím kỳ diệu**, bo góc lớn, chữ Fredoka/Nunito thân
/// thiện. Đồng bộ với `wonderlens-mockup.html`.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WonderColors.wonder, // tím kỳ diệu
    brightness: Brightness.light,
  ).copyWith(
    primary: WonderColors.wonder,
    secondary: WonderColors.spark,
    surface: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: WonderColors.canvasTop, // oải hương dịu
  );

  final textTheme = buildWonderTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WonderColors.wonder,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: WonderType.display(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
    ),
  );
}
