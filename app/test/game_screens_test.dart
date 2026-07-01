// Smoke test cho mini-game gắn 1 vật vừa khám phá (TASK-018 / B):
// QuizScreen + AssemblyGameScreen render đúng và fallback an toàn khi thiếu data.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/material_catalog.dart';
import 'package:wonderlens/data/mission_repository.dart';
import 'package:wonderlens/models/assembly.dart';
import 'package:wonderlens/models/mission.dart';
import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/models/quiz.dart';
import 'package:wonderlens/screens/assembly_game_screen.dart';
import 'package:wonderlens/screens/missions_screen.dart';
import 'package:wonderlens/screens/quiz_screen.dart';

void main() {
  setUpAll(() async {
    // Assembly/Quiz đọc MaterialCatalog.instance khi khởi tạo → nạp catalog thật.
    final raw = await File('assets/content/materials.json').readAsString();
    MaterialCatalog.debugInstance = MaterialCatalog.fromJsonString(raw);
  });

  const withGames = ObjectContent(
    id: 'ball_pen',
    name: 'Bút bi',
    emoji: '🖊️',
    materialBadge: 'Nhựa',
    stages: <Stage>[],
    quiz: <QuizQuestion>[
      QuizQuestion(
        question: 'Vỏ bút bi làm từ gì?',
        options: <String>['Nhựa', 'Gỗ', 'Vải'],
        answerIndex: 0,
        explain: 'Vỏ bút làm từ nhựa.',
      ),
    ],
    assembly: Assembly(
      target: 'Bút bi',
      steps: <AssemblyStep>[
        AssemblyStep(from: 'petroleum', to: 'plastic', label: 'Dầu mỏ → hạt nhựa'),
        AssemblyStep(from: 'plastic', to: 'ball_pen', label: 'Hạt nhựa → bút bi'),
      ],
    ),
  );

  const noGames = ObjectContent(
    id: 'x',
    name: 'Vật lạ',
    emoji: '✨',
    materialBadge: '',
    stages: <Stage>[],
  );

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump();
    // Cho Timer nền (blob) chạy hết trước teardown, tránh "Timer still pending".
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('QuizScreen hiện câu hỏi đầu tiên', (tester) async {
    await pumpScreen(tester, const QuizScreen(content: withGames));
    expect(find.text('Vỏ bút bi làm từ gì?'), findsOneWidget);
    expect(find.text('Câu 1/1'), findsOneWidget);
    expect(find.text('Nhựa'), findsOneWidget);
  });

  testWidgets('QuizScreen thiếu quiz → trạng thái đang chuẩn bị', (tester) async {
    await pumpScreen(tester, const QuizScreen(content: noGames));
    expect(find.text('Đố vui đang được chuẩn bị'), findsOneWidget);
  });

  testWidgets('AssemblyGameScreen hiện kho nguyên liệu để kéo', (tester) async {
    await pumpScreen(tester, const AssemblyGameScreen(content: withGames));
    expect(find.text('Kho nguyên liệu'), findsOneWidget);
    // Node nguyên liệu resolve tên qua MaterialCatalog (dầu mỏ / hạt nhựa).
    expect(find.textContaining('Dầu mỏ'), findsWidgets);
  });

  testWidgets('AssemblyGameScreen thiếu assembly → trạng thái đang chuẩn bị',
      (tester) async {
    await pumpScreen(tester, const AssemblyGameScreen(content: noGames));
    expect(find.text('Trò ghép ngược đang được chuẩn bị'), findsOneWidget);
  });

  testWidgets('MissionsScreen liệt kê nhiệm vụ + tiến độ (D1)', (tester) async {
    MissionRepository.debugMissions = const <Mission>[
      Mission(
        id: 'metal_hunt',
        title: 'Thợ săn kim loại',
        emoji: '🧲',
        goal: MissionGoal(
          type: MissionType.materialCount,
          category: 'Kim loại',
          count: 3,
        ),
        rewardBadge: 'Huy hiệu Thợ săn kim loại',
      ),
    ];
    await pumpScreen(tester, const MissionsScreen());
    expect(find.text('Thợ săn kim loại'), findsOneWidget);
    // Chưa khám phá vật nào → tiến độ 0/3.
    expect(find.text('Tiến độ 0/3'), findsOneWidget);
  });
}
