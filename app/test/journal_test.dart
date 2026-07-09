// Nhật ký "Khám phá thêm (AI)": vật lạ được lưu bền + round-trip nội dung,
// dedup theo id, hero không vào nhật ký (vẫn theo luồng discovered cũ).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wonderlens/data/collection_repository.dart';
import 'package:wonderlens/models/object_content.dart';

ObjectContent _live(String id, String name) => ObjectContent(
  id: id,
  name: name,
  emoji: '🥄',
  materialBadge: 'Gỗ',
  stages: const [
    Stage(title: 'Từ cây gỗ', kidText: 'Người ta cưa gỗ thành khúc nhỏ.'),
    Stage(title: 'Mài nhẵn', kidText: 'Chiếc thìa được mài thật nhẵn.'),
  ],
  source: 'live',
  history: 'Thìa gỗ có từ rất lâu rồi.',
  story: 'Ngày xưa, có một khúc gỗ nhỏ...',
);

void main() {
  late Directory tmp;
  late Box box;
  final repo = CollectionRepository();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('wonderlens_journal_test');
    Hive.init(tmp.path);
    box = await Hive.openBox('test_collection');
    CollectionRepository.debugSetBox(box);
  });

  tearDown(() async {
    CollectionRepository.debugSetBox(null);
    await box.deleteFromDisk();
    await Hive.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('vật AI-live vào nhật ký: vật mới, không huy hiệu, round-trip đủ', () {
    final r = repo.record(_live('wooden_spoon', 'Thìa gỗ'));
    expect(r.isNewObject, isTrue);
    expect(r.newBadge, isNull); // vật AI không mở huy hiệu vật liệu

    // Không rơi vào danh sách hero.
    expect(repo.discoveredIds(), isEmpty);

    final entries = repo.journalEntries();
    expect(entries, hasLength(1));
    final e = entries.first;
    expect(e.id, 'wooden_spoon');
    expect(e.name, 'Thìa gỗ');

    // Mở lại từ nhật ký: nội dung nguyên vẹn, nguồn 'live' để giữ nhãn AI.
    final content = e.toContent();
    expect(content.source, 'live');
    expect(content.name, 'Thìa gỗ');
    expect(content.stages, hasLength(2));
    expect(content.stages.first.kidText, 'Người ta cưa gỗ thành khúc nhỏ.');
    expect(content.story, 'Ngày xưa, có một khúc gỗ nhỏ...');
    expect(content.narrationText, isNotEmpty);
  });

  test('dedup theo id + mới nhất đứng đầu', () {
    expect(repo.record(_live('wooden_spoon', 'Thìa gỗ')).isNewObject, isTrue);
    expect(repo.record(_live('wooden_spoon', 'Thìa gỗ')).isNewObject, isFalse);
    expect(repo.record(_live('clay_pot', 'Nồi đất')).isNewObject, isTrue);

    final ids = [for (final e in repo.journalEntries()) e.id];
    expect(ids, ['clay_pot', 'wooden_spoon']);
  });

  test('id rỗng hoặc unknown không vào nhật ký', () {
    expect(repo.record(_live('', 'Vô danh')).isNewObject, isFalse);
    expect(repo.record(_live('unknown', 'Vật bí ẩn')).isNewObject, isFalse);
    expect(repo.journalEntries(), isEmpty);
  });

  test('hero vào discovered như cũ, không vào nhật ký', () {
    const hero = ObjectContent(
      id: 'paper_cup',
      name: 'Cốc giấy',
      emoji: '🥤',
      materialBadge: 'Giấy',
      stages: [],
    );
    final r = repo.record(hero);
    expect(r.isNewObject, isTrue);
    expect(r.newBadge, 'Giấy');
    expect(repo.discoveredIds(), ['paper_cup']);
    expect(repo.journalEntries(), isEmpty);

    // Khám phá lại: không nhân đôi.
    expect(repo.record(hero).isNewObject, isFalse);
    expect(repo.discoveredIds(), ['paper_cup']);
  });

  test('containsObject và remove xoá hero khỏi discovered', () {
    const hero = ObjectContent(
      id: 'paper_cup',
      name: 'Cốc giấy',
      emoji: '🥤',
      materialBadge: 'Giấy',
      stages: [],
    );

    repo.record(hero);
    expect(repo.containsObject('paper_cup'), isTrue);
    expect(repo.remove('paper_cup'), isTrue);
    expect(repo.containsObject('paper_cup'), isFalse);
    expect(repo.discoveredIds(), isEmpty);
    expect(repo.badges(), isEmpty);

    expect(repo.remove('paper_cup'), isFalse);
  });

  test('remove xoá vật AI-live khỏi journal và giữ mục hỏng', () {
    repo.record(_live('wooden_spoon', 'Thìa gỗ'));
    box.put('journal', <String>[
      '{không phải json',
      ...(box.get('journal') as List).cast<String>(),
    ]);

    expect(repo.containsObject('wooden_spoon'), isTrue);
    expect(repo.remove('wooden_spoon'), isTrue);
    expect(repo.containsObject('wooden_spoon'), isFalse);
    expect(repo.journalEntries(), isEmpty);
    expect((box.get('journal') as List), hasLength(1));
  });

  test('mục nhật ký hỏng bị bỏ qua khi đọc, không crash, không bị xoá', () {
    box.put('journal', <String>['{không phải json']);
    expect(repo.journalEntries(), isEmpty);

    // Ghi vật mới vẫn giữ nguyên chuỗi hỏng (phòng schema đổi giữa bản app).
    repo.record(_live('clay_pot', 'Nồi đất'));
    expect(repo.journalEntries().single.id, 'clay_pot');
    expect((box.get('journal') as List), hasLength(2));
  });
}
