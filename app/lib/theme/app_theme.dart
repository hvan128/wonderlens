// Flutter 3.44 chuyển CupertinoPageTransitionsBuilder sang thư viện cupertino.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'wonder_tokens.dart';

/// Theme trẻ em: màu vui tươi, bo góc lớn, chữ đậm dễ đọc.
///
/// Màu/bo góc lấy từ `wonder_tokens.dart` — một nguồn sự thật, tránh lệch giá
/// trị giữa theme Material và design system kính.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WonderColors.teal, // teal vui mắt
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    // Nunito làm font mặc định toàn app: mọi TextStyle thô (không set family)
    // kế thừa qua DefaultTextStyle — không phải sửa từng call-site (ADR-010).
    fontFamily: WonderType.bodyFamily,
    scaffoldBackgroundColor: WonderColors.paper, // giấy ấm
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WonderTokens.radiusLg),
        ),
        // Giữ số 28/16 nguyên bản (28 = space24 + space4) — không có token
        // đơn khớp, cộng token chỉ làm khó đọc.
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: WonderType.button.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      // Radius 24 là bo góc card Material thuần, không thuộc thang bo góc
      // kính (radiusMd 20 / radiusLg 28) — giữ nguyên số, không ép vào token.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
    ),
    // Chỉ ảnh hưởng MaterialPageRoute (Dev panel → Playground);
    // go_router dùng wonderPage riêng nên không đi qua đây.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
