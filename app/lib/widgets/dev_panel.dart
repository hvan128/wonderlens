import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../screens/playground_screen.dart';
import '../ui/ui.dart';

/// Bảng Dev ẩn: chuyển **Mock offline ↔ API thật** + chỉnh Proxy URL/token ngay
/// lúc runtime (không cần build lại). Mở bằng cử chỉ ẩn (long-press logo
/// onboarding hoặc nhãn "CHẾ ĐỘ KHÁM PHÁ" ở camera).
Future<void> showDevPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _DevPanel(),
  );
}

class _DevPanel extends StatefulWidget {
  const _DevPanel();

  @override
  State<_DevPanel> createState() => _DevPanelState();
}

class _DevPanelState extends State<_DevPanel> {
  late final TextEditingController _url =
      TextEditingController(text: AppSettings.baseUrl);
  late final TextEditingController _token =
      TextEditingController(text: AppSettings.appToken);
  bool _obscure = true;

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final messenger = ScaffoldMessenger.of(context);
    AppSettings.setBaseUrlOverride(_url.text);
    AppSettings.setTokenOverride(_token.text);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Đã lưu nguồn nhận diện')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(WonderTokens.radiusXl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: WonderColors.textSoft.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    const PhosphorIcon(
                      PhosphorIconsBold.flask,
                      size: 22,
                      color: WonderColors.grape,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nguồn nhận diện (Dev)',
                      style: TextStyle(
                        color: WonderColors.textStrong,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Bật API thật để gọi OpenAI Vision qua proxy. Tắt = Mock '
                  'offline (xoay tua lần lượt 8 vật hero).',
                  style: TextStyle(
                    color: WonderColors.textSoft,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: AppSettings.liveMode,
                  builder: (_, live, _) => _ModeToggle(
                    live: live,
                    onChanged: (v) => AppSettings.useLiveApi = v,
                  ),
                ),
                const SizedBox(height: 18),
                _Field(label: 'Proxy URL', controller: _url),
                const SizedBox(height: 12),
                _Field(
                  label: 'App token (x-app-token)',
                  controller: _token,
                  obscure: _obscure,
                  trailing: IconButton(
                    icon: Icon(
                      _obscure ? Symbols.visibility : Symbols.visibility_off,
                      size: 20,
                      fill: 1,
                    ),
                    color: WonderColors.textSoft,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Để trống = dùng giá trị lúc build (--dart-define). URL công '
                  'khai an toàn; token là bí mật, phải khớp APP_SHARED_SECRET '
                  'của proxy.',
                  style: TextStyle(
                    color: WonderColors.textSoft,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                GlassButton(
                  label: 'Lưu & đóng',
                  icon: Symbols.check,
                  onTap: _saveAndClose,
                ),
                const SizedBox(height: 12),
                GlassButton(
                  label: 'Playground UI v2',
                  icon: PhosphorIconsFill.sparkle,
                  onTap: () {
                    // Bắt Navigator TRƯỚC khi pop — sau pop, context của sheet
                    // deactivate, tra cứu ancestor không còn an toàn (cùng lý
                    // do _saveAndClose bắt ScaffoldMessenger trước khi pop).
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PlaygroundScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool live;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.live, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final accent = live ? WonderColors.teal : WonderColors.sunny;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(WonderTokens.radiusMd),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            live ? Symbols.cloud_done : Symbols.cloud_off,
            size: 24,
            fill: 1,
            weight: 600,
            color: live ? WonderColors.tealDeep : WonderColors.sunnyDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  live ? 'API thật (OpenAI Vision)' : 'Mock offline (xoay tua)',
                  style: TextStyle(
                    color: WonderColors.textStrong,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  live
                      ? 'Chụp → nhận diện thật + AI-live cho vật lạ'
                      : 'Chụp → lần lượt 8 vật hero (demo offline)',
                  style: TextStyle(
                    color: WonderColors.textSoft,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: live,
            onChanged: onChanged,
            activeThumbColor: WonderColors.teal,
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Widget? trailing;
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: WonderColors.textStrong,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.url,
          style: TextStyle(color: WonderColors.textStrong, fontSize: 14.5),
          decoration: InputDecoration(
            isDense: true,
            suffixIcon: trailing,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
              borderSide:
                  BorderSide(color: WonderColors.textSoft.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(WonderTokens.radiusSm),
              borderSide: const BorderSide(color: WonderColors.teal, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
