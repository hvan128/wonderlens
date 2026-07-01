import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/material_catalog.dart';
import 'package:wonderlens/services/learn_play_service.dart';

/// Test logic So sánh 2 vật (TASK-010 / D8). Nạp catalog thật từ asset file.
void main() {
  late LearnPlayService service;

  setUpAll(() async {
    final raw = await File('assets/content/materials.json').readAsString();
    service = LearnPlayService(MaterialCatalog.fromJsonString(raw));
  });

  test('điểm chung trực tiếp: hai vật cùng vật liệu', () {
    final r = service.compare('ball_pen', 'plastic_bottle');
    expect(r.shared, contains('plastic'));
    expect(r.link, ComparisonLink.shared);
    expect(r.onlyA, contains('steel')); // bút bi còn có thép
    expect(r.onlyB, isEmpty); // chai nhựa chỉ có nhựa
  });

  test('nguồn gốc chung: khác trực tiếp nhưng cùng gốc (gỗ)', () {
    // Bút chì (gỗ, than chì) vs Tờ giấy A4 (bột giấy ← gỗ).
    final r = service.compare('pencil', 'paper_a4');
    expect(r.shared, isEmpty);
    expect(r.sharedOrigin, contains('wood'));
    expect(r.link, ComparisonLink.originOnly);
  });

  test('hoàn toàn khác nhau: không chung trực tiếp lẫn nguồn gốc', () {
    // Bút chì (gỗ/than chì) vs Kẹp giấy (thép ← quặng sắt).
    final r = service.compare('pencil', 'paper_clip');
    expect(r.shared, isEmpty);
    expect(r.sharedOrigin, isEmpty);
    expect(r.link, ComparisonLink.none);
  });

  test('thiếu dữ liệu: vật lạ/AI-live không có vật liệu → không crash', () {
    final r = service.compare('ball_pen', 'khong_ton_tai');
    expect(r.shared, isEmpty);
    expect(r.sharedOrigin, isEmpty);
    expect(r.onlyA, isNotEmpty);
    expect(r.onlyB, isEmpty);
    expect(r.link, ComparisonLink.none);
  });

  test('expandedMaterials gồm cả chuỗi nguồn gốc', () {
    expect(
      service.expandedMaterials('paper_cup'),
      containsAll(<String>['paper_pulp', 'wood', 'plastic', 'petroleum']),
    );
  });
}
