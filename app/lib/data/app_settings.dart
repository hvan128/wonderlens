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
  static const _kOnboardingSeen = 'onboarding_seen';

  /// Giá trị nhúng lúc build (qua `--dart-define`).
  static const envBaseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: '',
  );
  static const envToken = String.fromEnvironment(
    'APP_TOKEN',
    defaultValue: 'dev-wonderlens',
  );

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
    // Dọn override token/URL cũ trong Hive để giá trị nhúng lúc build
    // (dart-define APP_TOKEN / PROXY_BASE_URL) LUÔN thắng — tránh kẹt token sai
    // đã lưu từ phiên trước gây 401 dù build đã có token đúng.
    await box.delete(_kToken);
    await box.delete(_kUrl);
    // Mặc định LUÔN bật AI thật (bỏ chế độ mock/dev làm mặc định). Mỗi lần chụp
    // sẽ gọi AI sinh hành trình cho mọi vật. Cần proxy + token hợp lệ (dart-define
    // APP_TOKEN) — offline/lỗi thì báo thân thiện, không rớt về vật hero mock.
    liveMode.value = true;
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

  /// Test-only: ghi đè trạng thái đã xem onboarding mà không cần Hive box.
  @visibleForTesting
  static bool? debugOnboardingSeenOverride;

  /// Test-only: gắn box Hive mở sẵn (pattern giống CollectionRepository) để
  /// test khoá được hợp đồng persist (vd cờ onboarding_seen).
  @visibleForTesting
  static void debugSetBox(Box? box) {
    _box = box;
  }

  /// Bé đã đi qua (hoặc bỏ qua) màn onboarding chưa — quyết định splash sẽ
  /// dẫn vào '/onboarding' hay thẳng '/home'.
  static bool get onboardingSeen {
    final override = debugOnboardingSeenOverride;
    if (override != null) return override;
    return (_box?.get(_kOnboardingSeen) as bool?) ?? false;
  }

  /// Đánh dấu đã xem onboarding (bền qua Hive — chỉ hiện đúng một lần).
  static void markOnboardingSeen() {
    _box?.put(_kOnboardingSeen, true);
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
