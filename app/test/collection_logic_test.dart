// Kiểm logic thuần của bộ sưu tập: tên cấp độ theo số vật + tra cứu catalog.
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/data/collection_repository.dart';
import 'package:wonderlens/data/hero_catalog.dart';

void main() {
  test('levelTitle tăng theo số vật khám phá', () {
    expect(levelTitle(0), contains('Mầm tò mò'));
    expect(levelTitle(1), contains('Tân binh'));
    expect(levelTitle(3), contains('manh mối'));
    expect(levelTitle(5), contains('khoa học'));
    expect(levelTitle(heroCatalog.length), contains('Bậc thầy'));
  });

  test('heroById trả đúng vật và null khi không có', () {
    expect(heroById('paper_cup')?.name, 'Cốc giấy');
    expect(heroById('ball_pen')?.material, 'Nhựa');
    expect(heroById('khong_ton_tai'), isNull);
  });

  test('mọi material của catalog nằm trong allMaterials', () {
    for (final h in heroCatalog) {
      expect(allMaterials, contains(h.material));
    }
  });
}
