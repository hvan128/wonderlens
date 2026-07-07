# Phase 03 — Lấp trống coverage + verify tổng

## Context

Sau khi có lớp trung tâm (01) và notification haptic (02), thêm rung vào các trạng thái
đang **im lặng** — chủ yếu là lỗi/cảnh báo và điều hướng — để phản hồi nhất quán.

## Điểm bổ sung

| Chỗ | File (khoảng) | Sự kiện | Gọi |
|---|---|---|---|
| Camera — hết quyền / lỗi ống kính | `screens/camera_screen.dart` ~134/143/170 | khi set `_error` do denied | `WonderHaptics.error()` |
| Camera — lỗi chụp | `screens/camera_screen.dart` ~234 (catch) | capture thất bại | `WonderHaptics.error()` |
| Video hành trình — lỗi | `widgets/journey_video.dart` ~99/117 | vào `_Phase.error` | `WonderHaptics.error()` |
| Share — lỗi | `widgets/share_sheet.dart` (catch của `_share`) | share thất bại | `WonderHaptics.error()` |
| Share — thành công | `widgets/share_sheet.dart` (sau share OK) | chia sẻ xong | `WonderHaptics.success()` |
| Onboarding — đổi trang | `screens/onboarding_screen.dart` (`onPageChanged` của PageView) | trang settle | `WonderHaptics.selection()` |

Tùy chọn (dev-only, minor — làm nếu rẻ):
- `widgets/dev_panel.dart` Switch `onChanged` → `WonderHaptics.selection()`.

### Nguyên tắc chọn loại

- **error()**: thao tác của bé thất bại (không quyền, chụp hỏng, video/share lỗi).
- **success()**: hoàn tất có phần thưởng/kết quả (share xong; reward vật mới đã có ở timeline).
- **selection()**: điều hướng nhẹ (đổi trang onboarding, toggle).
- **warning()**: chỉ dùng nếu có bước xác nhận/nhắc quyền rõ ràng; hiện chưa bắt buộc.

> Không spam: mỗi sự kiện rung **một lần**. Với camera error được set nhiều lần trong 1
> luồng, chỉ rung khi `_error` chuyển từ null → có (tránh rung lặp mỗi rebuild).

## Loại trừ (cố ý không thêm)

- `wonder_chip` — tĩnh, không bấm được.
- Không thêm haptic cho scroll/timeline thường (chỉ reward mới rung).
- Không gate theo Reduce Motion (đã nêu ở plan).

## Verify tổng (DoD)

1. `grep -rn "HapticFeedback\." app/lib | grep -v wonder_haptics.dart` → **rỗng**.
2. `cd app && flutter analyze` → sạch.
3. `cd app && flutter test` → pass (cập nhật test nếu có snapshot đổi; không nới lỏng assert).
4. Build: `flutter build apk --debug` (hoặc theo memory `wonderlens-build-token-gotcha` nếu
   cần AI live) + build iOS 1 lần để chắc pod/SPM resolve.
5. Thử tay device thật: tap nút, scan, chụp, share OK/lỗi, video lỗi, mở khi hết quyền,
   swipe onboarding, nhận vật mới → cảm nhận đúng loại haptic.

## Docs

- ADR-011 đã ghi quyết định dependency (phase 02).
- Không đụng `specs/api-contracts.md` (haptic là UX nội bộ, không phải contract).
- Cân nhắc 1 dòng trong `AGENTS.md`/design doc: "mọi haptic đi qua `WonderHaptics`".

## Rollback

Từng điểm bổ sung độc lập; revert theo commit.
