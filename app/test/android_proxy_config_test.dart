import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/app_settings.dart';

void main() {
  test('Android production proxy uses the Hiep-owned Vercel project', () {
    expect(
      AppSettings.publicProxyUrl,
      'https://wonderlens-android-proxy.vercel.app',
    );
    expect(AppSettings.baseUrl, AppSettings.publicProxyUrl);
  });
}
