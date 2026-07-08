import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wonderlens/data/capture_store.dart';
import 'package:wonderlens/data/collection_repository.dart';
import 'package:wonderlens/screens/collection_screen.dart';
import 'package:wonderlens/screens/day_detail_screen.dart';
import 'package:wonderlens/screens/home_screen.dart';
import 'package:wonderlens/screens/profile_screen.dart';
import 'package:wonderlens/theme/app_theme.dart';
import 'package:wonderlens/ui/ui.dart';

/// Sinh screenshot marketing cho App Store / Google Play từ CHÍNH widget thật
/// của app, khung iPhone 6.7" (1290×2796 = 430×932 logic @3x). Dữ liệu demo
/// seed qua Hive box như journal_test. Ảnh asset decode thật nhờ runAsync.
///
/// Chạy: `flutter test tool/pregen_store_screenshots.dart` (từ app/).
/// Xuất: store-assets/screenshots/65_0N-<tên>.png — dùng chung cả hai store.
const _outDir = 'store-assets/screenshots';
final _shotKey = GlobalKey();

JournalEntry _entry(String id, String name, String emoji, DateTime at) =>
    JournalEntry(id: id, name: name, emoji: emoji, discoveredAt: at, content: const {});

/// Nạp MỌI font trong FontManifest (font app + font icon của package như
/// material_symbols/iconsax) — thiếu font icon thì icon thành ô tofu. Family
/// dạng `packages/x/y` nạp thêm dưới tên đã lột prefix vì engine tra cả hai.
Future<void> _loadAppFonts() async {
  final manifest = jsonDecode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final assets = (entry['fonts'] as List<dynamic>)
        .map((f) => (f as Map<String, dynamic>)['asset'] as String);
    final names = <String>{
      family,
      if (family.startsWith('packages/')) family.split('/').last,
    };
    for (final name in names) {
      final loader = FontLoader(name);
      for (final asset in assets) {
        loader.addFont(rootBundle.load(asset));
      }
      await loader.load();
    }
  }
}

/// Pump màn hình trong theme thật, chờ ảnh asset decode, chụp @3x.
Future<void> _shot(WidgetTester tester, Widget screen, String file) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        // Bọc như MainShell thật: màn tab nhận nền chấm từ shell, thiếu nó
        // ProfileScreen chụp ra nền đen.
        home: Scaffold(body: WonderBackground(child: screen)),
      ),
    ),
  );
  // Vài nhịp thật (runAsync) cho Image.asset decode xong, xen kẽ pump để
  // frame sau vẽ ảnh vừa decode. KHÔNG pumpAndSettle — có animation vô hạn.
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 120),
        ));
    await tester.pump(const Duration(milliseconds: 40));
  }
  final boundary = _shotKey.currentContext!.findRenderObject()!
      as RenderRepaintBoundary;
  final image =
      (await tester.runAsync(() => boundary.toImage(pixelRatio: 3)))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  ))!;
  final out = File('$_outDir/$file')..parent.createSync(recursive: true);
  out.writeAsBytesSync(bytes.buffer.asUint8List());
  // In kích thước để đối chiếu slot 6.7" (1290×2796).
  // ignore: avoid_print
  print('  $file: ${image.width}x${image.height}');
}

void main() {
  late Directory tmp;
  late Box box;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('wonderlens_screenshots');
    Hive.init(tmp.path);
    box = await Hive.openBox('screenshot_collection');
    CollectionRepository.debugSetBox(box);

    // Ảnh cutout demo (pregen-demo-captures.mjs) đóng vai "ảnh bé chụp" —
    // thiếu ảnh nào thì vật đó rớt về emoji như hành vi thật của app.
    final capturesDir = Directory('store-assets/demo-captures');
    final captureIds = capturesDir.existsSync()
        ? capturesDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png'))
            .map((f) => f.uri.pathSegments.last.replaceAll('.png', ''))
        : const Iterable<String>.empty();
    CaptureStore.debugSetStore(capturesDir, captureIds);

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    await box.put('discovered', <String>['paper_cup', 'pencil', 'plastic_bottle']);
    await box.put('journal', <String>[
      _entry('wooden_spoon', 'Thìa gỗ', '🥄', today).toJsonString(),
      _entry('clay_pot', 'Nồi đất', '🏺', today).toJsonString(),
      _entry('rubber_duck', 'Vịt cao su', '🦆', yesterday).toJsonString(),
      _entry('glass_cup', 'Cốc thuỷ tinh', '🥛', yesterday).toJsonString(),
      _entry('wool_hat', 'Mũ len', '🧶', yesterday).toJsonString(),
    ]);
  });

  tearDown(() async {
    CaptureStore.debugSetStore(null, const []);
    CollectionRepository.debugSetBox(null);
    await box.deleteFromDisk();
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  testWidgets('chup bo screenshot store 6.7 inch', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // File IO thật phải chạy trong runAsync — FakeAsync không bơm event IO,
    // await trần sẽ treo test.
    await tester.runAsync(_loadAppFonts);

    final today = DateTime.now();
    final shots = <String, Widget>{
      '65_01-home.png': const HomeScreen(),
      '65_02-day-detail.png': DayDetailView(
        entries: [
          _entry('wooden_spoon', 'Thìa gỗ', '🥄', today),
          _entry('clay_pot', 'Nồi đất', '🏺', today),
        ],
        color: const Color(0xFFA9B79D),
        onClose: () {},
        onCapture: () {},
        onOpenEntry: (_) {},
      ),
      '65_03-collection.png': const CollectionScreen(),
      '65_04-profile.png': const ProfileScreen(),
    };

    final failed = <String>[];
    for (final e in shots.entries) {
      try {
        await _shot(tester, e.value, e.key);
      } catch (err) {
        failed.add('${e.key}: $err');
      }
      // Xả exception tồn đọng của màn này để không lây sang màn sau.
      tester.takeException();
    }
    // ignore: avoid_print
    if (failed.isNotEmpty) print('FAILED:\n${failed.join('\n')}');
    expect(failed, isEmpty, reason: 'một số màn không chụp được');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
