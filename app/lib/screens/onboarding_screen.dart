import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/pulse.dart';

/// Màn chào: mascot dẫn dắt, 1 nút bắt đầu khám phá.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Pulse(child: Text('🔍✨', style: TextStyle(fontSize: 80))),
              const SizedBox(height: 16),
              Text(
                'WonderLens',
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'Chĩa máy ảnh vào một đồ vật, rồi chụp nhé!\nMình sẽ kể cho bạn nghe nó được làm ra như thế nào. 🧪',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 36),
              FilledButton(
                onPressed: () => context.push('/camera'),
                child: const Text('Bắt đầu khám phá 🚀'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/collection'),
                child: const Text('Bộ sưu tập của tôi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
