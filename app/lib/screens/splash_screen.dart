import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/app_settings.dart';
import '../ui/ui.dart';

/// Màn chào thương hiệu lúc mở app: logo khẩu độ + wordmark trên nền canvas
/// sáng, đứng lại một nhịp ngắn rồi tự dẫn tiếp — lần đầu vào '/onboarding'
/// (chụp thử), các lần sau vào thẳng '/home'. Chạm bất kỳ đâu để đi ngay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Thời gian đứng ở splash trước khi tự chuyển màn.
  static const Duration hold = Duration(milliseconds: 1400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(SplashScreen.hold, _next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(AppSettings.onboardingSeen ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context);

    Widget brand = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const WonderLogo(size: 112),
        const SizedBox(height: WonderTokens.space24),
        Text(
          'WonderLens',
          style: WonderType.display.copyWith(
            color: WonderColors.textStrong,
            fontSize: 34,
          ),
        ),
        const SizedBox(height: WonderTokens.space8),
        Text(
          'Chiếc kính nhỏ soi chuyện đồ vật',
          style: WonderType.body.copyWith(color: WonderColors.textSoft),
        ),
      ],
    );

    if (!reduce) {
      brand = brand
          .animate()
          .fadeIn(duration: WonderTokens.durSlow)
          .scaleXY(
            begin: 0.86,
            end: 1,
            duration: WonderTokens.durSlow,
            curve: WonderTokens.curveEmphasized,
          );
    }

    return Scaffold(
      // Chạm để đi ngay — không bắt bé đợi hết nhịp chào.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: WonderBackground(child: Center(child: brand)),
      ),
    );
  }
}
