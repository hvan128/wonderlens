import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonderlens/data/material_catalog.dart';
import 'package:wonderlens/models/object_content.dart';
import 'package:wonderlens/models/quiz.dart';
import 'package:wonderlens/services/learn_play_service.dart';

/// Test Đố vui sau timeline (TASK-009 / C3): parse + chấm điểm + an toàn.
void main() {
  late LearnPlayService service;
  late ObjectContent ballPen;

  setUpAll(() async {
    final mats = await File('assets/content/materials.json').readAsString();
    service = LearnPlayService(MaterialCatalog.fromJsonString(mats));
    final raw = await File('assets/content/ball_pen.json').readAsString();
    ballPen = ObjectContent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  });

  test('parse quiz[] từ content hero', () {
    expect(ballPen.quiz, isNotEmpty);
    expect(ballPen.quiz.first.options.length, greaterThanOrEqualTo(2));
    expect(ballPen.quiz.every((q) => q.isValid), isTrue);
  });

  test('chấm điểm: đúng hết → đủ sao', () {
    final answers = ballPen.quiz.map((q) => q.answerIndex).toList();
    final r = service.scoreQuiz(ballPen.quiz, answers);
    expect(r.correct, ballPen.quiz.length);
    expect(r.total, ballPen.quiz.length);
    expect(r.stars, 3);
  });

  test('chấm điểm: sai hết → vẫn ≥1 sao (không "phạt")', () {
    final answers = ballPen.quiz
        .map((q) => (q.answerIndex + 1) % q.options.length)
        .toList();
    final r = service.scoreQuiz(ballPen.quiz, answers);
    expect(r.correct, 0);
    expect(r.stars, greaterThanOrEqualTo(1));
  });

  test('QuizQuestion.isCorrect đúng/sai', () {
    const q = QuizQuestion(
      question: 'x',
      options: <String>['a', 'b'],
      answerIndex: 1,
    );
    expect(q.isCorrect(1), isTrue);
    expect(q.isCorrect(0), isFalse);
  });

  test('câu hỏi hỏng bị loại khi parse (thiếu / ngoài phạm vi)', () {
    final c = ObjectContent.fromJson(<String, dynamic>{
      'id': 'x',
      'name': 'X',
      'quiz': <Map<String, dynamic>>[
        {'question': '', 'options': ['a', 'b'], 'answer_index': 0},
        {'question': 'ok', 'options': ['a'], 'answer_index': 0},
        {'question': 'ok2', 'options': ['a', 'b'], 'answer_index': 5},
        {'question': 'good', 'options': ['a', 'b'], 'answer_index': 1},
      ],
    });
    expect(c.quiz.length, 1);
    expect(c.quiz.first.question, 'good');
  });

  test('vật thiếu quiz → rỗng, không crash', () {
    final c = ObjectContent.fromJson(<String, dynamic>{'id': 'x', 'name': 'X'});
    expect(c.quiz, isEmpty);
  });
}
