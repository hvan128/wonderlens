import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ui/ui.dart';

/// Hai liên kết pháp lý (Chính sách quyền riêng tư · Điều khoản) mở trong
/// trình duyệt hệ thống. Đặt ở chân màn Hồ sơ để reviewer store và phụ huynh
/// truy cập được ngay trong app. Lỗi mở link thì im lặng bỏ qua (không chặn
/// UI) — đây là điều hướng phụ, không phải luồng chính.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  static final Uri _privacy =
      Uri.parse('https://wonderlens-proxy.vercel.app/privacy');
  static final Uri _terms =
      Uri.parse('https://wonderlens-proxy.vercel.app/terms');

  Future<void> _open(Uri url) async {
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Không có trình duyệt / lỗi nền tảng → bỏ qua, không làm vỡ màn.
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = WonderType.caption.copyWith(
      color: WonderColors.textSoft.withValues(alpha: 0.9),
      decoration: TextDecoration.underline,
    );
    Widget link(String label, Uri url) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _open(url),
          child: Text(label, style: style),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        link('Chính sách quyền riêng tư', _privacy),
        Text(
          '  ·  ',
          style: WonderType.caption.copyWith(
            color: WonderColors.textSoft.withValues(alpha: 0.5),
          ),
        ),
        link('Điều khoản', _terms),
      ],
    );
  }
}
