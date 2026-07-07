import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/wonder_tokens.dart';
import 'motion.dart';

/// Trang go_router với hiệu ứng chuyển màn Material "shared axis" — mượt, có
/// chiều, đồng bộ toàn app. fillColor trong suốt để không chớp nền khi đè lên
/// camera/kính. Khi hệ điều hành bật Reduce Motion → chỉ crossfade, không slide.
CustomTransitionPage<T> wonderPage<T>({
  required LocalKey key,
  required Widget child,
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
  bool fade = false,
}) {
  return CustomTransitionPage<T>(
    key: key,
    transitionDuration: WonderTokens.durBase,
    reverseTransitionDuration: WonderTokens.durBase,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // fade = true (vd vào hành trình): chỉ cross-fade để nối liền mạch với màn
      // tách-nền, không "trượt sang màn khác".
      if (fade || reduceMotionOf(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: type,
        fillColor: Colors.transparent,
        child: child,
      );
    },
  );
}
