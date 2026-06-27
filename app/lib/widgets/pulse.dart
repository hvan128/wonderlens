import 'package:flutter/material.dart';

/// Hiệu ứng phóng to/thu nhỏ nhẹ nhàng, lặp lại — dùng cho mascot/nút mời chạm.
class Pulse extends StatefulWidget {
  final Widget child;
  final double maxScale;
  const Pulse({super.key, required this.child, this.maxScale = 1.12});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: widget.maxScale,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
