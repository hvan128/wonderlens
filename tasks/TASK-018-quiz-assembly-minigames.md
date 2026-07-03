# TASK-018: Mini-game gắn 1 vật vừa khám phá (B) + CTA "Chơi tiếp" (A3)

**Owner:** Dev
**Status:** In Progress
**Branch:** feature/TASK-018-quiz-assembly-minigames
**Ref ADR:** [ADR-013](../adrs/ADR-013-learn-play-domain.md) · [ADR-012](../adrs/ADR-012-material-graph-model.md)
**Depends:** [TASK-017](TASK-017-game-integration-foundation.md)

## Bối cảnh

Sau khi có nền game (TASK-017), mở "cửa vào" đầu tiên: biến mỗi lần khám phá thành
một lượt chơi ngắn về **chính vật đó** — đúng lúc trẻ đang hứng thú ở cuối Timeline
(ý tưởng A3 + B trong `wonderlens-ui-brainstorm.html`). Hai trò đã dựng sẵn ở nhánh
`integration/truc-c-d` (Domain 5 Learn & Play): **Đố vui** (quiz) và **Ghép ngược** (assembly).

## Goal

- Port màn **QuizScreen** (`/quiz`) + **AssemblyGameScreen** (`/assembly`), khớp design
  system hiện tại (tím + Tia + Fredoka/Nunito), nhận `ObjectContent` qua `extra`.
- **A3:** thêm thẻ "Chơi tiếp với {tên vật}" ở cuối Timeline, chỉ hiện trò **có dữ liệu**
  (`quiz` không rỗng / `assembly != null`), điều hướng sang game.
- Không "phạt": trả lời sai vẫn được Tia giải thích + hoàn thành vẫn nhận sao; thả sai
  trong ghép ngược chỉ là gợi ý. Offline cho hero; vật thiếu game → trạng thái "đang chuẩn bị".

## Phạm vi

IN:
- `lib/screens/quiz_screen.dart`, `lib/screens/assembly_game_screen.dart` (port + reskin).
- Route `/quiz`, `/assembly` trong `lib/router.dart` (nhận `ObjectContent?` qua `state.extra`, dùng `wonderPage`).
- `_PlayNextSection` (A3) trong `timeline_screen.dart` — chèn giữa "Bạn vừa khám phá xong 🎉"
  và nút "Khám phá vật khác"; `context.push('/quiz'|'/assembly', extra: c)`.
- Thêm icon `puzzlePiece` vào `ui/phosphor_compat.dart`; hook test `MaterialCatalog.debugInstance`.
- Smoke test `test/game_screens_test.dart` (render + fallback thiếu data).

OUT (task sau):
- Nhiệm vụ + section Bộ sưu tập (A2) → TASK-019. Streak (D2) → TASK-020. Tab Sân chơi (A1) → TASK-021.
- Ghi phần thưởng quiz/assembly vào Hive (`RewardEarned`/`quiz_badges`) — chưa nối vào track huy hiệu
  (giữ đơn giản; huy hiệu hiện chỉ hiển thị trong màn game).

## Acceptance Criteria

- [x] `flutter analyze` sạch.
- [x] `flutter test` pass — thêm 4 smoke test (quiz/assembly render + fallback), không hồi quy (55 pass).
- [x] Cuối Timeline hiện CTA game **chỉ khi** vật có `quiz`/`assembly`; vật thiếu → không hiện, không crash.
- [x] `/quiz` & `/assembly` nhận `ObjectContent` qua `extra`; back an toàn (`canPop` → pop, else `/collection`).
- [x] Vật thiếu quiz/assembly mở thẳng route → màn "đang chuẩn bị", không crash.

## DoD

- [x] Code đúng phạm vi + AC; business logic ở `LearnPlayService` (không trong widget).
- [x] `flutter analyze` sạch · `flutter test` pass · build pass.
- [ ] Verify trên app thật (quét vật → cuối Timeline chơi được quiz/ghép ngược).
- [ ] PR reviewed & merged.
