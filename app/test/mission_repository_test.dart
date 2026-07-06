import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:wonderlens/data/material_catalog.dart';
import 'package:wonderlens/data/mission_repository.dart';
import 'package:wonderlens/models/mission.dart';

/// Test Nhiệm vụ (TASK-011 / D6): tiến độ thuần + persist/dedup qua Hive.
void main() {
  late MaterialCatalog catalog;

  setUpAll(() async {
    final raw = await File('assets/content/materials.json').readAsString();
    catalog = MaterialCatalog.fromJsonString(raw);
  });

  group('parse + tiến độ (thuần)', () {
    late List<Mission> missions;

    setUpAll(() async {
      final raw = await File('assets/content/missions.json').readAsString();
      missions = MissionRepository.parseMissions(raw);
    });

    Mission byId(String id) => missions.firstWhere((m) => m.id == id);

    MissionProgress prog(
      Mission m, {
      Set<String> discovered = const <String>{},
      Set<String> unlocked = const <String>{},
    }) =>
        MissionRepository.progressOf(
          m,
          discovered: discovered,
          unlockedCards: unlocked,
          catalog: catalog,
        );

    test('parse hợp lệ, đủ loại goal', () {
      expect(missions, isNotEmpty);
      expect(missions.every((m) => m.isValid), isTrue);
    });

    test('material_count đếm theo nhóm qua mạng lưới vật liệu', () {
      final m = byId('metal_hunt'); // Kim loại, count 3
      // pencil có than chì (Kim loại) → tính 1.
      expect(prog(m, discovered: {'pencil'}).current, 1);
      final done = prog(m, discovered: {'ball_pen', 'paper_clip', 'battery_aa'});
      expect(done.current, 3);
      expect(done.done, isTrue);
    });

    test('discover_set đếm đúng các vật trong bộ', () {
      final m = byId('office_set');
      final p = prog(m, discovered: {'ball_pen', 'pencil'});
      expect(p.current, 2);
      expect(p.done, isFalse);
    });

    test('collect_card hoàn thành khi đủ thẻ', () {
      final m = byId('oil_family'); // petroleum + plastic
      expect(prog(m, unlocked: {'petroleum', 'plastic'}).done, isTrue);
    });

    test('tham chiếu không tồn tại / chưa khám phá → an toàn, 0', () {
      final m = byId('metal_hunt');
      expect(prog(m, discovered: {'khong_ton_tai'}).current, 0);
      expect(prog(m).current, 0);
    });
  });

  group('persist + dedup (Hive)', () {
    setUpAll(() {
      Hive.init(Directory.systemTemp.createTempSync('wl_mission_test').path);
    });

    test('ghi nhận hoàn thành, dedup, persist qua mở lại box', () async {
      final box = await Hive.openBox('wl_progress_test');
      MissionRepository.debugBox = box;
      MissionRepository.debugMissions = const <Mission>[
        Mission(
          id: 'm1',
          title: 'Thử',
          emoji: '🧲',
          goal: MissionGoal(
            type: MissionType.discoverSet,
            objectIds: <String>['ball_pen'],
          ),
          rewardBadge: 'B',
        ),
      ];
      final repo = MissionRepository();

      final newly1 = repo.syncCompletions(
        discovered: {'ball_pen'},
        unlockedCards: const <String>{},
        catalog: catalog,
      );
      expect(newly1.map((m) => m.id), <String>['m1']);
      expect(repo.completedIds(), contains('m1'));

      // Lần 2: dedup — không trao lại.
      final newly2 = repo.syncCompletions(
        discovered: {'ball_pen'},
        unlockedCards: const <String>{},
        catalog: catalog,
      );
      expect(newly2, isEmpty);

      // Persist: đóng + mở lại box.
      await box.close();
      final box2 = await Hive.openBox('wl_progress_test');
      MissionRepository.debugBox = box2;
      expect(MissionRepository().completedIds(), contains('m1'));
    });
  });
}
