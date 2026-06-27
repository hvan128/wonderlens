import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cấu hình runtime (bền qua Hive) để chuyển **Mock offline ↔ API thật** ngay
/// trong app, không cần build lại. Mặc định theo cấu hình lúc build:
/// có `PROXY_BASE_URL` (qua `--dart-define`) → bật API thật; ngược lại → Mock.
///
/// Dùng pattern static giống [CollectionRepository] để service đọc đồng bộ
/// tại thời điểm gọi; [liveMode] cho UI (Dev panel) lắng nghe cập nhật tức thì.
class AppSettings {
  static const _boxName = 'wonderlens_settings';
  static const _kLive = 'use_live_api';
  static const _kUrl = 'proxy_base_url';
  static const _kToken = 'app_token';

  /// Giá trị nhúng lúc build (qua `--dart-define`).
  static const envBaseUrl =
      String.fromEnvironment('PROXY_BASE_URL', defaultValue: '');
  static const envToken =
      String.fromEnvironment('APP_TOKEN', defaultValue: 'dev-wonderlens');

  /// Proxy công khai (URL không phải bí mật — an toàn để nhúng). Làm fallback
  /// khi build mock-only nhưng người dùng bật API thật từ Dev panel.
  static const publicProxyUrl = 'https://wonderlens-proxy.vercel.app';

  static Box? _box;

  /// Cờ bật API thật; UI lắng nghe để bật/tắt switch tức thì.
  static final ValueNotifier<bool> liveMode = ValueNotifier<bool>(false);

  /// Gọi 1 lần lúc khởi động app (sau hoặc trước [CollectionRepository.init]).
  static Future<void> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox(_boxName);
    _box = box;
    final stored = box.get(_kLive) as bool?;
    liveMode.value = stored ?? envBaseUrl.isNotEmpty;
  }

  static bool get useLiveApi => liveMode.value;

  static set useLiveApi(bool value) {
    liveMode.value = value;
    _box?.put(_kLive, value);
  }

  /// URL proxy hiệu lực: override (Dev panel) → build env → proxy công khai.
  static String get baseUrl {
    final override = (_box?.get(_kUrl) as String?)?.trim();
    if (override != null && override.isNotEmpty) return override;
    if (envBaseUrl.isNotEmpty) return envBaseUrl;
    return publicProxyUrl;
  }

  /// Token hiệu lực: override (Dev panel) → build env (sample mặc định).
  static String get appToken {
    final override = (_box?.get(_kToken) as String?)?.trim();
    if (override != null && override.isNotEmpty) return override;
    return envToken;
  }

  /// Lưu override URL (chuỗi rỗng = xoá override, quay về giá trị build).
  static void setBaseUrlOverride(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      _box?.delete(_kUrl);
    } else {
      _box?.put(_kUrl, v);
    }
  }

  /// Lưu override token (chuỗi rỗng = xoá override, quay về giá trị build).
  static void setTokenOverride(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      _box?.delete(_kToken);
    } else {
      _box?.put(_kToken, v);
    }
  }
}
