import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/material_catalog.dart';
import 'package:wonderlens/models/object_content.dart';

/// Test đồ thị vật liệu (TASK-008 / ADR-007). Nạp catalog thật từ asset file
/// (cwd = thư mục package `app/` khi chạy `flutter test`).
void main() {
  late MaterialCatalog catalog;

  setUpAll(() async {
    final raw = await File('assets/content/materials.json').readAsString();
    catalog = MaterialCatalog.fromJsonString(raw);
  });

  test('catalog nạp đủ vật liệu nguồn + chế biến', () {
    expect(catalog.all.length, greaterThanOrEqualTo(8));
    expect(catalog.byId('petroleum')?.isSource, isTrue);
    expect(catalog.byId('plastic')?.isSource, isFalse);
  });

  test('materialsOf: trả vật liệu của hero, rỗng cho vật lạ/AI-live', () {
    expect(
      catalog.materialsOf('ball_pen'),
      containsAll(<String>['plastic', 'steel']),
    );
    expect(catalog.materialsOf('khong_ton_tai'), isEmpty);
  });

  test('objectsUsing: các hero cùng một vật liệu (mạng lưới)', () {
    expect(
      catalog.objectsUsing('steel'),
      containsAll(<String>['ball_pen', 'paper_clip', 'battery_aa']),
    );
    expect(catalog.objectsUsing('plastic'), contains('plastic_bottle'));
  });

  test('sharedMaterials: tìm điểm chung của 2 vật', () {
    expect(catalog.sharedMaterials('ball_pen', 'paper_cup'), <String>['plastic']);
    expect(catalog.sharedMaterials('paper_a4', 'battery_aa'), isEmpty);
  });

  test('derivationChain: dựng chuỗi nguồn → chế biến', () {
    expect(catalog.derivationChain('plastic'), <String>['petroleum', 'plastic']);
    expect(catalog.derivationChain('steel'), <String>['iron_ore', 'steel']);
    expect(catalog.derivationChain('petroleum'), <String>['petroleum']);
  });

  test('unlockedCards: suy từ discoveredIds + mở cả chuỗi nguồn gốc', () {
    final unlocked = catalog.unlockedCards(<String>['ball_pen']);
    expect(
      unlocked,
      containsAll(<String>['plastic', 'steel', 'petroleum', 'iron_ore']),
    );
    expect(catalog.unlockedCards(const <String>[]), isEmpty);
  });

  test('ObjectContent thiếu materials không crash, mặc định rỗng', () {
    final c = ObjectContent.fromJson(<String, dynamic>{'id': 'x', 'name': 'X'});
    expect(c.materials, isEmpty);
  });
}
