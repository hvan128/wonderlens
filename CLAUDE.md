# CLAUDE.md — WonderLens

> Claude Code project rules. Đây là luật cao nhất cho phiên làm việc trong repo này.

## Bắt buộc đọc trước khi làm bất cứ gì

Đọc theo thứ tự này — **không bỏ bước**:

1. `docs/workflow.md` — quy trình & nguyên tắc vận hành
2. `AGENTS.md` — luật repo (stack, convention, Git, content schema)
3. `specs/prd.md` — business goals, features, risks
4. `specs/domains.md` — domain split, ownership, contracts
5. `specs/api-contracts.md` — API + local schema (bao gồm video journey)
6. `adrs/` — tất cả ADR (quyết định kiến trúc)
7. Task hiện tại trong `tasks/` — Goal, AC, DoD

**Chỉ sau khi đọc đủ → mới đọc/sửa code.**

## Quy tắc cứng (không thương lượng)

### Trước khi code
- [ ] Task có Goal + AC rõ chưa? Nếu không → hỏi, không tự code
- [ ] Đã đọc spec + ADR liên quan chưa?
- [ ] Domain ownership rõ chưa? (xem `specs/domains.md`)

### Trong khi code
- [ ] Không gọi OpenAI trực tiếp từ Flutter app — luôn qua proxy
- [ ] Không commit API key, secret bất kỳ
- [ ] Không thêm dependency mới mà không có ADR
- [ ] Business logic không viết trong widget
- [ ] Khi sửa schema/API → cập nhật `specs/api-contracts.md` ngay

### Trước khi push
- [ ] `flutter analyze` sạch
- [ ] `flutter test` pass
- [ ] `proxy` TypeScript: `tsc --noEmit` sạch
- [ ] Build không lỗi
- [ ] Docs cập nhật nếu có thay đổi contract/schema

### Git
- Không push thẳng `main`
- Branch: `feature/TASK-XXX-slug`
- Commit: `TASK-XXX: mô tả ngắn gọn`
- PR bắt buộc trước merge

## Khi AI sai

Sửa **context** trước khi đổi prompt hay model:
1. Task có Goal + AC đúng không?
2. Spec / ADR liên quan có còn đúng không?
3. Contract có khớp implementation không?
4. `AGENTS.md` có bị vi phạm không?

## Video Journey (feature mới)

`specs/api-contracts.md` đã có schema video. Khi làm việc liên quan:
- Video asset: `app/assets/videos/{object_id}_making.mp4`
- Poster: `app/assets/images/{object_id}_video_poster.png`
- Trường `video` là **optional** — app không crash nếu thiếu
- Vật không có video bundled (gồm AI live): app **tự sinh phim runtime qua
  proxy** (ngầm, tắt tiếng, optional) — lỗi thì hiện "Thử lại", không chặn flow
- Nếu video lỗi: fallback poster + timeline text

## Định nghĩa Done

Task chỉ Done khi **tất cả** checklist sau pass:
- [ ] Code đúng spec + AC
- [ ] `flutter test` pass
- [ ] Build pass
- [ ] Docs/contracts cập nhật
- [ ] Tuân ADR + AGENTS.md
- [ ] PR reviewed & merged
