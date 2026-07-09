# TASK-013: Long press vật phẩm trong rương

**Owner:** Dev
**Status:** Code Done — `flutter test`, Android debug build, iOS debug no-codesign build pass
**Branch:** local

## Goal

Cho phép bé nhấn giữ một vật phẩm để quản lý vật đó: lưu ảnh thẻ sticker về thư
viện ảnh của máy, hoặc xoá khỏi rương và ảnh sticker local của app.

## Acceptance Criteria

- [ ] Nhấn giữ vật trong Rương mở sheet hành động.
- [ ] Vật đang có trong Rương có thể xoá khỏi Hive local và biến khỏi UI ngay.
- [ ] Ảnh cutout local của vật bị xoá cùng lúc để không hiện lại ảnh cũ.
- [ ] Bấm "Lưu vào Ảnh" xuất ảnh thẻ sticker vào Photos/MediaStore của máy:
      nền giấy cũ, vật có viền trắng, tên có viền trắng.
- [ ] Tap thường vẫn mở lại timeline như trước.

## DoD

- `flutter test` pass trong scope collection/journal.
- Không thêm dependency mới.
- Không đổi proxy/API OpenAI.
