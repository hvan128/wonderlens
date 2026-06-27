import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wonder_tokens.dart';

/// Hệ chữ WonderLens — nguồn sự thật duy nhất cho typography.
///
/// - **Fredoka** (bo tròn, vui) cho tiêu đề / wordmark / con số to.
/// - **Nunito** (dễ đọc, hỗ trợ tiếng Việt) cho nội dung.
///
/// Nạp qua `google_fonts` (xem `adrs/ADR-006-typography.md`). Dùng
/// [WonderType.display] / [WonderType.body] cho text tuỳ biến; text không khai
/// font tự thừa kế Nunito qua [buildWonderTextTheme].
abstract final class WonderType {
  /// Tiêu đề bo tròn (Fredoka).
  static TextStyle display({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.fredoka(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  /// Nội dung dễ đọc (Nunito).
  static TextStyle body({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

/// Dựng [TextTheme]: Nunito cho toàn bộ, Fredoka cho nhóm display/headline/title
/// lớn. Text dùng `Theme.of(context).textTheme.*` hoặc text thô (thừa kế
/// bodyMedium) đều có font đúng.
TextTheme buildWonderTextTheme(TextTheme base) {
  final nunito = GoogleFonts.nunitoTextTheme(base).apply(
    bodyColor: WonderColors.textStrong,
    displayColor: WonderColors.textStrong,
  );
  TextStyle fredoka(TextStyle? s, FontWeight w) =>
      GoogleFonts.fredoka(textStyle: s, fontWeight: w);
  return nunito.copyWith(
    displayLarge: fredoka(nunito.displayLarge, FontWeight.w700),
    displayMedium: fredoka(nunito.displayMedium, FontWeight.w700),
    displaySmall: fredoka(nunito.displaySmall, FontWeight.w600),
    headlineLarge: fredoka(nunito.headlineLarge, FontWeight.w700),
    headlineMedium: fredoka(nunito.headlineMedium, FontWeight.w600),
    headlineSmall: fredoka(nunito.headlineSmall, FontWeight.w600),
    titleLarge: fredoka(nunito.titleLarge, FontWeight.w600),
  );
}
