import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/material_catalog.dart';
import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/services/learn_play_service.dart';

/// Test Ghép ngược (TASK-012 / C2): parse + luật chuỗi + an toàn.
void main() {
  late LearnPlayService service;

  setUpAll(() async {
    final mats = await File('assets/content/materials.json').readAsString();
    service = LearnPlayService(MaterialCatalog.fromJsonString(mats));
  });

  Future<ObjectContent> load(String id) async {
    final raw = await File('assets/content/$id.json').readAsString();
    return ObjectContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  test('parse assembly từ hero content', () async {
    final c = await load('ball_pen');
    expect(c.assembly, isNotNull);
    expect(c.assembly!.steps.length, greaterThanOrEqualTo(2));
    expect(c.assembly!.target, 'Bút bi');
  });

  test('assemblyChain dựng đúng chuỗi node', () async {
    final c = await load('ball_pen');
    expect(
      service.assemblyChain(c.assembly!),
      <String>['petroleum', 'plastic', 'ball_pen'],
    );
  });

  test('isNextInChain validate thứ tự đúng/sai', () {
    final chain = <String>['petroleum', 'plastic', 'ball_pen'];
    expect(service.isNextInChain(chain, 0, 'petroleum'), isTrue);
    expect(service.isNextInChain(chain, 0, 'plastic'), isFalse);
    expect(service.isNextInChain(chain, 1, 'plastic'), isTrue);
    expect(service.isNextInChain(chain, 3, 'ball_pen'), isFalse);
  });

  test('assembly hỏng (thiếu steps) → null, không crash', () {
    final c = ObjectContent.fromJson(<String, dynamic>{
      'id': 'x',
      'name': 'X',
      'assembly': <String, dynamic>{'target': 'X', 'steps': <dynamic>[]},
    });
    expect(c.assembly, isNull);
  });

  test('vật thiếu assembly → null', () {
    final c = ObjectContent.fromJson(<String, dynamic>{'id': 'x', 'name': 'X'});
    expect(c.assembly, isNull);
  });

  test('đủ 4 hero có công thức ghép', () async {
    for (final id in <String>['ball_pen', 'pencil', 'paper_a4', 'plastic_bottle']) {
      final c = await load(id);
      expect(c.assembly, isNotNull, reason: id);
    }
  });
}
