# TASK-022: Polish UI/UX toàn app (bố cục & component học Duolingo)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-022-ui-polish-duolingo
**Ref ADR:** [ADR-010](../adrs/ADR-010-typography.md) (typography) · [ADR-016](../adrs/ADR-016-bottom-nav-shell.md) (bottom-nav shell)
**Depends:** [TASK-021](TASK-021-playground-tab.md)

## Bối cảnh

Hệ visual "tím kỳ diệu + mascot Tia + Fredoka/Nunito + liquid glass" đã chốt (TASK-015,
ADR-010) — **giữ nguyên style**. Task này chỉ nâng chất lượng thị giác & UX từng component
theo pattern Duolingo: nút "chunky 3D" có cạnh lún khi bấm, bottom-nav có active state rõ,
progress bar thống nhất, celebration sống động, màu phản hồi tokenize.

## Goal

Toàn bộ màn hình đẹp và nhất quán hơn trong cùng hệ style hiện có — không đổi flow,
routes, contract, copy.

## Phạm vi

IN (lớp nền — `lib/theme`, `lib/ui`):
- Tokens: thêm màu phản hồi `success/danger/honey`; hết hex rải rác cho 3 màu này.
- `WonderButton`: nâng thành nút 3D kiểu Duolingo (cạnh dưới sẫm + mặt nút lún khi bấm),
  API giữ nguyên.
- `WonderProgressBar`: thêm vệt gloss; dùng thống nhất thay các bản tự chế.
- `WonderBottomNav`: emoji → icon vector, active pill + màu; label giữ nguyên.
- `phosphor_compat`: bổ sung icon dùng chung; fix hex lệch brand (scan ring `#EAF8FB`,
  header `#D9F6FB`/`#7A4E00`, glass `#7A4E00`).

IN (từng màn — `lib/screens`, `lib/widgets`):
- playground, missions, quiz, assembly, material_cards, collection, timeline,
  streak_celebration, share_sheet/share_card, camera (status card), onboarding (micro).
- Emoji-làm-icon điều hướng/action → PhosphorIcon; emoji là **content** (vật/vật liệu) giữ.
- Bổ sung empty/loading state còn thiếu (missions, material-cards guard `isReady`,
  timeline null-fallback, playground tap feedback).
- Tiêu đề dùng Fredoka (`WonderType.display`) thống nhất; spacing bám thang 4pt.

OUT:
- Không đổi navigation/routes (camera ngoài shell — ADR-016); không đổi schema/contract;
- Không thêm dependency mới; không đổi business logic/services;
- Không đổi các label/copy mà test đang assert (vd `Sân chơi`, `Tiến độ 0/3`,
  `Chuỗi 3 ngày! 🔥`, `Kho nguyên liệu`…).

## Acceptance Criteria

- [x] `flutter analyze` sạch.
- [x] `flutter test` pass — không hồi quy (65 test pass).
- [x] WonderButton 3D áp dụng mọi CTA; bấm có cảm giác lún + haptic.
- [x] Bottom-nav icon vector + active state; label/tap không đổi.
- [x] Collection + Missions dùng `WonderProgressBar` chung (bỏ 2 bản tự chế;
      share_card dùng bản chung với `animate: Duration.zero` để render PNG).
- [x] Màu success/danger/honey là token; không còn `Color(0xFF2EBD85)`/`0xFFE5564E`/
      `0xFFE08A00` inline ở screens.
- [x] Không còn emoji làm icon nav/action; emoji content giữ nguyên.
- [x] Empty/loading state: missions + material-cards có guard `isReady`; timeline
      null-fallback có style; playground có busy state khi bấm thẻ trò.
- [ ] Verify trên app thật (cảm giác nút 3D, active tab, celebration streak).

## DoD

- [x] Code đúng phạm vi + AC; không business logic trong widget.
- [x] `flutter analyze` sạch · `flutter test` pass (65/65) · build pass.
- [x] Docs/contracts: không đổi contract (đã xác nhận — chỉ thay đổi visual).
- [ ] PR reviewed & merged.

## Ghi chú thực hiện

- Lớp nền: WonderButton 3D (cạnh sẫm + lún 4px — tổng cao `height + 4`),
  WonderProgressBar thêm gloss, bottom-nav icon vector + pill active, tokens
  `success/danger/honey`, xoá `wonder_palette.dart` (dead code, không ai import),
  fix hex lệch brand teal cũ (scan ring `#EAF8FB`→canvasTop, wordmark `#D9F6FB`→
  wonderSoft, `#7A4E00`→onSpark), header/wordmark dùng Fredoka.
- share_card đổi nền teal/navy → tím (wonderDeep→ink) cho khớp brand.
- Quiz: sao kết quả ⭐ emoji → icon star vector scale-in; đáp án đúng/sai có
  check/x + shake. Assembly: mũi tên '↓' text → icon; slot đặt đúng scale-pulse.
- Streak celebration: choreography mascot scale-in + dot "bốc cháy" stagger,
  dot 🔥 → icon fire (title `Chuỗi N ngày! 🔥` giữ nguyên — test assert).
