// Kiểm logic thuần của bộ sưu tập: tên cấp độ theo số vật + tra cứu catalog.
import 'package:flutter_test/flutter_test.dart';

import 'package:wonderlens/data/collection_repository.dart';
import 'package:wonderlens/data/hero_catalog.dart';

void main() {
  test('levelTitle tăng theo số vật khám phá', () {
    expect(levelTitle(0), contains('Người mới'));
    expect(levelTitle(1), contains('Thám tử'));
    expect(levelTitle(3), contains('khám phá'));
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

  group('normalizeMaterial (huy hiệu động AI — ADR-011)', () {
    test('đồng nghĩa & hoa/thường gộp về tên canonical', () {
      expect(normalizeMaterial('nhựa'), 'Nhựa');
      expect(normalizeMaterial('Chất dẻo'), 'Nhựa');
      expect(normalizeMaterial('PLASTIC'), 'Nhựa');
      expect(normalizeMaterial('thủy tinh'), 'Thuỷ tinh');
      expect(normalizeMaterial('Kính'), 'Thuỷ tinh');
      expect(normalizeMaterial('  gỗ  '), 'Gỗ');
      expect(normalizeMaterial('inox'), 'Kim loại');
    });

    test('rỗng/space → ""', () {
      expect(normalizeMaterial(''), '');
      expect(normalizeMaterial('   '), '');
    });

    test('vật liệu lạ giữ nguyên nhưng title-case', () {
      expect(normalizeMaterial('silicone'), 'Silicone');
      expect(normalizeMaterial('sợi carbon'), 'Sợi Carbon');
    });
  });
}
