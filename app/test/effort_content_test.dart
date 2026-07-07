// Parse predict/action/experiment (TASK-011): dữ liệu chuẩn parse đủ trường,
// dữ liệu hỏng/thiếu → null (fallback hành vi cũ, không crash).
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/models/object_content.dart';

void main() {
  group('StagePredict.fromJson', () {
    test('dữ liệu chuẩn → parse đủ trường', () {
      final p = StagePredict.fromJson({
        'question': 'Dầu mỏ sẽ biến thành gì tiếp theo?',
        'options': ['Hạt nhựa nhỏ xíu', 'Nước ngọt', 'Cục đá'],
        'answer_index': 0,
        'hint': 'Nghĩ xem vỏ bút cứng làm bằng gì nhỉ?',
      });
      expect(p, isNotNull);
      expect(p!.question, contains('Dầu mỏ'));
      expect(p.options, hasLength(3));
      expect(p.answerIndex, 0);
      expect(p.hint, isNotNull);
    });

    test('answer_index ngoài phạm vi options → null', () {
      final p = StagePredict.fromJson({
        'question': 'Q?',
        'options': ['A', 'B'],
        'answer_index': 2,
      });
      expect(p, isNull);
    });

    test('dưới 2 lựa chọn → null', () {
      final p = StagePredict.fromJson({
        'question': 'Q?',
        'options': ['A'],
        'answer_index': 0,
      });
      expect(p, isNull);
    });

    test('thiếu question / không phải map → null', () {
      expect(
        StagePredict.fromJson({
          'options': ['A', 'B'],
          'answer_index': 0,
        }),
        isNull,
      );
      expect(StagePredict.fromJson(null), isNull);
      expect(StagePredict.fromJson('predict'), isNull);
    });
  });

  group('StageAction.fromJson', () {
    test('type hợp lệ → parse được', () {
      final a = StageAction.fromJson({'type': 'hold', 'label': 'Nhấn giữ'});
      expect(a, isNotNull);
      expect(a!.type, 'hold');
      expect(a.label, 'Nhấn giữ');
    });

    test('type lạ hoặc thiếu label → null', () {
      expect(StageAction.fromJson({'type': 'shake', 'label': 'Lắc'}), isNull);
      expect(StageAction.fromJson({'type': 'tap', 'label': ''}), isNull);
      expect(StageAction.fromJson(null), isNull);
    });
  });

  group('HomeExperiment.fromJson', () {
    test('đủ trường → parse được, title mặc định khi thiếu', () {
      final e = HomeExperiment.fromJson({
        'prompt': 'Thả kẹp giấy vào cốc nước — chìm hay nổi?',
        'reveal': 'Thép nặng hơn nước nên chìm.',
        'badge': 'Nhà khoa học nhí',
      });
      expect(e, isNotNull);
      expect(e!.title, 'Nhiệm vụ mini tại nhà');
      expect(e.badge, 'Nhà khoa học nhí');
    });

    test('thiếu prompt → null', () {
      expect(HomeExperiment.fromJson({'title': 'Thử nghiệm'}), isNull);
      expect(HomeExperiment.fromJson(null), isNull);
    });
  });

  test('ObjectContent.fromJson nối đủ predict/action/experiment vào model', () {
    final c = ObjectContent.fromJson({
      'id': 'ball_pen',
      'name': 'Bút bi',
      'stages': [
        {
          'title': 'Chặng 0',
          'kid_text': 'Mở đầu.',
          'action': {'type': 'hold', 'label': 'Nhấn giữ để bơm dầu'},
        },
        {
          'title': 'Chặng 1',
          'kid_text': 'Tiếp theo.',
          'predict': {
            'question': 'Q?',
            'options': ['Đúng', 'Sai'],
            'answer_index': 0,
          },
        },
      ],
      'experiment': {'prompt': 'Thử viết ngược cây bút xem!'},
    });
    expect(c.stages[0].action?.type, 'hold');
    expect(c.stages[0].predict, isNull);
    expect(c.stages[1].predict?.options, hasLength(2));
    expect(c.experiment?.prompt, contains('viết ngược'));
  });

  test(
    'content cũ không có field mới → parse bình thường (backward-compat)',
    () {
      final c = ObjectContent.fromJson({
        'id': 'pencil',
        'name': 'Bút chì',
        'stages': [
          {'title': 'Chặng', 'kid_text': 'Chữ.'},
        ],
      });
      expect(c.stages.single.predict, isNull);
      expect(c.stages.single.action, isNull);
      expect(c.experiment, isNull);
    },
  );
}
