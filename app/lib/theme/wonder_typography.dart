import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'wonder_tokens.dart';

/// Hệ chữ WonderLens — nguồn sự thật duy nhất cho typography.
///
/// - **Baloo 2** (bo tròn, mập, vui) cho tiêu đề / wordmark / con số to —
///   hỗ trợ đầy đủ dấu tiếng Việt (thay Fredoka vốn thiếu bảng chữ Việt,
///   render sai dấu chồng ố/ầ/ấ… — xem `adrs/ADR-017-display-font-vietnamese.md`).
/// - **Nunito** (dễ đọc, hỗ trợ tiếng Việt) cho nội dung.
///
/// Nạp qua `google_fonts` (ADR-010). Dùng [WonderType.display] /
/// [WonderType.body] cho text tuỳ biến; text không khai font tự thừa kế Nunito
/// qua [buildWonderTextTheme].
abstract final class WonderType {
  /// Tiêu đề bo tròn (Baloo 2).
  static TextStyle display({
    double? fontSize,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.baloo2(
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

/// Dựng [TextTheme]: Nunito cho toàn bộ, Baloo 2 cho nhóm display/headline/title
/// lớn. Text dùng `Theme.of(context).textTheme.*` hoặc text thô (thừa kế
/// bodyMedium) đều có font đúng.
TextTheme buildWonderTextTheme(TextTheme base) {
  final nunito = GoogleFonts.nunitoTextTheme(base).apply(
    bodyColor: WonderColors.textStrong,
    displayColor: WonderColors.textStrong,
  );
  TextStyle baloo(TextStyle? s, FontWeight w) =>
      GoogleFonts.baloo2(textStyle: s, fontWeight: w);
  return nunito.copyWith(
    displayLarge: baloo(nunito.displayLarge, FontWeight.w700),
    displayMedium: baloo(nunito.displayMedium, FontWeight.w700),
    displaySmall: baloo(nunito.displaySmall, FontWeight.w600),
    headlineLarge: baloo(nunito.headlineLarge, FontWeight.w700),
    headlineMedium: baloo(nunito.headlineMedium, FontWeight.w600),
    headlineSmall: baloo(nunito.headlineSmall, FontWeight.w600),
    titleLarge: baloo(nunito.titleLarge, FontWeight.w600),
  );
}
