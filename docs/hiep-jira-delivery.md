# Hoàng Hiệp — Jira delivery index

**Nguồn:** Atlassian MCP, project Wonderlens (`KAN`)  
**Assignee:** Hoàng Hiệp (`615a80e79cdb930072668cfe`)  
**Ngày kiểm kê:** 2026-07-15  
**Số task:** 13

## Cách đọc trạng thái

- **Repo ready:** deliverable đã được viết trong repo; chỉ chuyển sang trạng
  thái này sau link/content verification.
- **Review gate:** cần PM, legal, founder, safety hoặc tech lead phê duyệt.
- **External gate:** cần console/account/provider/live URL/publication; file Git
  không thể tự hoàn tất.
- `Repo ready` không đồng nghĩa Jira Done khi Acceptance Criteria/DoD còn review
  hoặc external gate.

## Traceability

| Jira | Summary | Deliverable | Repo outcome | Còn lại trước Jira Done |
|---|---|---|---|---|
| [KAN-4](https://aichoem.atlassian.net/browse/KAN-4) | Sprint 1 Plan | [Sprint scope](product/sprint-scope.md), [metrics](product/beta-success-metrics.md) | Repo ready | Core QA, PM scope, store deployment |
| [KAN-5](https://aichoem.atlassian.net/browse/KAN-5) | Product Scope & Sprint Definition | [Sprint scope](product/sprint-scope.md) | Repo ready | PM sign-off; quyết định online/curated-first |
| [KAN-6](https://aichoem.atlassian.net/browse/KAN-6) | Success metrics cho beta | [Beta metrics](product/beta-success-metrics.md) | Repo ready | Thu baseline/TestFlight data; PM duyệt target |
| [KAN-31](https://aichoem.atlassian.net/browse/KAN-31) | Privacy, age rating, Kids decision | [Privacy/age decision](release/privacy-age-rating.md) | Repo ready; recommendation | Legal/PM sign-off; sửa console declarations |
| [KAN-32](https://aichoem.atlassian.net/browse/KAN-32) | App Store metadata/screenshots | [Store metadata](release/store-metadata.md) | Repo ready một phần; copy + 6 screenshot | Thiếu camera hardware screenshot; PM upload |
| [KAN-34](https://aichoem.atlassian.net/browse/KAN-34) | Product Docs & Flow Handoff | [Product flows](handoff/product-flows.md) | Repo ready | PM review; link Jira tới doc |
| [KAN-35](https://aichoem.atlassian.net/browse/KAN-35) | Product + technical overview | [Overview](handoff/product-technical-overview.md) | Repo ready | PM/tech lead review |
| [KAN-36](https://aichoem.atlassian.net/browse/KAN-36) | Viral loop strategy | [Viral loops](growth/viral-loop-strategy.md) | Repo ready | PM chọn now/backlog; waitlist live |
| [KAN-37](https://aichoem.atlassian.net/browse/KAN-37) | Social calendar 30 ngày | [30-day calendar](growth/social-calendar-30-days.md) | Repo ready | Content/PM review; quay/schedule/post |
| [KAN-38](https://aichoem.atlassian.net/browse/KAN-38) | Build in public narrative | [Build in public](growth/build-in-public.md) | Repo ready | Reviewer duyệt từng claim; human publish |
| [KAN-39](https://aichoem.atlassian.net/browse/KAN-39) | Android beta landing/waitlist | [Waitlist spec](growth/android-beta-waitlist.md) | Repo ready; chưa live | Data owner, CRM, legal, live URL; submit test |
| [KAN-40](https://aichoem.atlassian.net/browse/KAN-40) | Press/launch kit | [Press kit](launch/press-kit.md) | Repo ready | Founder team note/contact; camera screenshot; PM review |
| [KAN-41](https://aichoem.atlassian.net/browse/KAN-41) | Product Hunt preparation | [Product Hunt draft](launch/product-hunt.md) | Repo ready; chưa launch | Closed beta pass; live waitlist; human maker comment; approval |

## Kết luận khả thi

### Có thể hoàn tất trong repo

- Product scope, beta metrics, JTBD/user/release flows và technical handoff.
- Privacy/store recommendation, metadata copy và asset/screenshot audit.
- Viral loops, 30-day calendar, build narrative, waitlist implementation spec,
  press kit và Product Hunt draft/runbook.

### Có thể làm thêm bằng code/tooling trong repo

- Tool đã sinh/mirror result + timeline screenshot từ widget thật và result có
  nhãn AI.
- Không thể chụp camera hardware đáng tin bằng widget test; camera screenshot
  cuối phải lấy từ build trên thiết bị/simulator phù hợp và QA thủ công.

### Không tự động hoàn tất

- PM/legal/founder sign-off.
- Store console submit/publish, social posting, Product Hunt scheduling.
- Waitlist live khi chưa có data controller, storage/CRM và retention process.
- Chuyển status hoặc comment Jira đại diện người dùng; yêu cầu hiện tại chỉ cho
  đọc task và triển khai repo.

## Thứ tự external recommend

1. PM chốt [sprint scope](product/sprint-scope.md), đặc biệt online-first vs
   curated-first.
2. Tech/QA chạy baseline và safety set theo [beta metrics](product/beta-success-metrics.md).
3. PM + legal duyệt [privacy/age decision](release/privacy-age-rating.md).
4. Hoàn tất core screenshots và metadata.
5. Chọn CRM/data owner, test waitlist end-to-end.
6. Mời Android closed beta, đo activation/retry/safety.
7. Chỉ sau beta ổn mới chạy public calendar/press/Product Hunt.

## Verification record

**Ngày chạy:** 2026-07-15  
**Branch:** `feature/TASK-017-hiep-jira-handoff`

- `flutter test`: **pass 91/91**.
- `flutter analyze`: **pass**, `No issues found`.
- `flutter build apk --release`: **pass**;
  `app/build/app/outputs/flutter-apk/app-release.apk` (97.9 MB).
- `flutter build ios --release --no-codesign`: **external toolchain blocker**,
  không phải lỗi Dart/repo. CocoaPods 1.17.0 đã được cài. Xcode 26.6 dùng SDK
  iOS 26.5.1 build `23F81a`, nhưng Apple catalog trả
  `iOS 26.5.1 (arm64Only) is not available for download`; runtime 26.5 build
  `23F73` không khớp và đã được xóa để trả 8 GB dung lượng. Tham chiếu:
  [Xcode 26.6 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_6-release-notes),
  [quản lý Xcode components](https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components).
- Tool screenshot: **pass**, đủ 6 ảnh `1290×2796` ở store-assets và Fastlane.
- Link nội bộ, asset manifest, Mermaid fence, secret scan và
  `git diff --check`: **pass**.
- Content counts: 30 ngày, 10 social drafts, 3 video scripts, 5
  build-in-public drafts; press copy đúng 50/150 từ cho VI/EN.
- Metadata lengths: subtitle 28, Play short 59, keywords 71, Product Hunt
  description 186 ký tự.

Commit triển khai/verification được ghi ở cuối
[TASK-017](../tasks/TASK-017-hiep-jira-handoff.md). Jira chưa bị đổi status hoặc
comment bởi phiên làm việc này.
