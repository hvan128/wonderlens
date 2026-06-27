import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/wonder_tokens.dart';

/// Bọc bất kỳ widget nào để có phản hồi chạm "mềm": thu nhỏ nhẹ + haptic.
/// Dùng chung cho mọi nút/thẻ bấm được trong app.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) {
          _set(false);
          if (widget.haptic) HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1.0,
          duration: WonderTokens.durFast,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
