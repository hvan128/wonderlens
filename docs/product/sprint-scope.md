# Sprint scope — camera đến hành trình và beta release

**Jira:** [KAN-4](https://aichoem.atlassian.net/browse/KAN-4),
[KAN-5](https://aichoem.atlassian.net/browse/KAN-5)  
**Owner:** Hoàng Hiệp  
**Trạng thái:** Bản chờ PM review  
**Cập nhật:** 2026-07-15

## Core promise

> Bố mẹ cùng bé chụp một đồ vật thật và WonderLens biến nó thành một hành
> trình ngắn, dễ hiểu về vật liệu và cách món đồ được tạo ra.

Core flow của sprint là: **mở app → chụp → thấy kết quả → xem hành trình → lưu
hoặc chia sẻ**. Một thay đổi chỉ thuộc core khi giúp flow này nhanh hơn, an toàn
hơn hoặc đáng tin hơn trên bản beta.

## Kết quả sprint cần đạt

1. Một phụ huynh mới có thể hoàn tất core flow trên thiết bị thật mà không cần
   tài khoản hay hướng dẫn trực tiếp.
2. Ảnh không đi thẳng từ Flutter tới OpenAI; proxy validate, giữ key và trả lỗi
   thân thiện.
3. Nội dung AI-live có nhãn rõ, qua safety QA và không được mô tả như kiến thức
   đã kiểm chứng hoàn toàn.
4. Có build beta cài được, checklist TestFlight/closed testing, metadata và asset
   đủ để PM quyết định submit.

## Baseline hiện tại

| Hạng mục | Bằng chứng trong repo | Trạng thái thật |
|---|---|---|
| Flutter iOS/Android | `app/` | Có |
| Camera thật | `app/lib/screens/camera_screen.dart` | Có |
| Luồng production | `GenerateService` gọi `POST /api/generate` | Mọi ảnh cần mạng và AI |
| Kết quả/timeline | reveal trong camera + `TimelineScreen` | Có |
| Cutout | segmentation on-device + `CaptureStore` | Có, fallback an toàn |
| Nội dung curated | `app/assets/content/` | Có; dùng cho demo/mission/mở lại |
| Giọng đọc | OpenAI speech qua proxy, fallback `flutter_tts` | Có |
| Collection/journal | Hive local | Có |
| Chia sẻ | share card/sheet | Có |
| Store asset | icon, 4 screenshot, feature graphic | Có nhưng screenshot chưa phủ core flow |
| Production submit | báo cáo trong `plans/reports/` | Chưa có bằng chứng hoàn tất review |

Điểm cần chốt: [PRD](../../specs/prd.md) mô tả curated-first/offline cho hero,
nhưng camera production tại HEAD hiện gọi `/api/generate` cho mọi ảnh. Sprint
không được dùng target offline cũ để báo cáo trạng thái production hiện tại.

## In scope

### P0 — core flow

- Onboarding ngắn, xin quyền camera đúng ngữ cảnh.
- Chụp ảnh, trạng thái đang xử lý, huỷ/thử lại và thông báo mạng lỗi.
- Kết quả tên vật ngay sau hiệu ứng cutout.
- Timeline tiếng Việt, chữ ngắn, đọc được cho trẻ 6–10 tuổi.
- Ghi nhật ký/collection đúng lúc; mở lại không cần gọi AI lại khi đã cache.
- Share card phụ huynh có thể chủ động chia sẻ; không có public child profile.

### P0 — safety, privacy, reliability

- App chỉ gọi OpenAI qua Vercel proxy.
- Không commit secret; đổi token mẫu trước public beta.
- Request validation, giới hạn payload, timeout và lỗi không làm app crash.
- Red-team nội dung AI-live trước khi cho trẻ thật dùng.
- Privacy copy nói đúng: proxy không lưu ảnh, nhưng OpenAI có thể giữ nội dung
  trong abuse-monitoring logs tối đa 30 ngày theo cấu hình mặc định.
- Manual crash/safety/retry checklist cho beta; không thêm analytics trong sprint.

### P1 — release readiness

- Metadata App Store/Google Play nhất quán với audience gia đình.
- Screenshot phải có camera, kết quả, timeline/AI label và collection.
- Build release iOS/Android và smoke test trên thiết bị thật.
- Quyết định age/Kids/target audience qua PM + legal review.

## Secondary — làm sau khi P0 xanh

- Huy hiệu, trang hồ sơ, reminder local và polish collection.
- WonderLens Plus chỉ được bật giao dịch thật khi product IDs, store config,
  parental gate và review đều sẵn sàng.
- Ảnh chặng, speech và video AI-live là tăng cường; text timeline phải vẫn dùng
  được khi các media call lỗi.

## Out of scope của sprint

- Tài khoản trẻ, public profile, chat, feed hoặc chia sẻ giữa trẻ với nhau.
- Backend lưu journal, ảnh chụp hoặc hồ sơ học tập.
- Dashboard giáo viên, lớp học và B2B school admin.
- AR, nhiều ngôn ngữ, chủ đề curriculum mới quy mô lớn.
- Hệ analytics định danh, quảng cáo hoặc tracking chéo app.
- Tự dựng CRM/waitlist khi chưa có data owner, retention và consent approval.
- Product Hunt/public launch trước khi closed beta pass core QA.

## Backlog sau beta

- Khôi phục curated-first trong camera nếu offline hero là product requirement.
- Chuẩn hoá `specs/api-contracts.md` theo endpoint thực tế `/api/generate` và
  `/api/speech`.
- Backend receipt validation trước khi subscription có quy mô production.
- Mở rộng hero objects/content sau safety audit.
- Waitlist live, growth instrumentation và teacher pilot theo ADR riêng nếu có
  lưu dữ liệu bên ngoài thiết bị.

## Release gates

| Gate | Tiêu chí pass | Owner quyết định |
|---|---|---|
| Core QA | 30 core runs, không crash, kết quả/retry ghi đủ | QA/Dev |
| Safety | Không có lỗi critical trong red-team set | PM + safety reviewer |
| Privacy | Data flow, store disclosure, consent copy được duyệt | PM + legal |
| Assets | Screenshot phản ánh camera → result → learning | PM |
| Build | Test/analyze/build pass; device smoke test pass | Dev |
| Store | Console declarations đúng bản build | Release owner |

## PM sign-off

- [ ] Core promise được chấp nhận nguyên văn hoặc chỉnh trong file này.
- [ ] PM xác nhận production camera online-first là chủ ý hay yêu cầu khôi phục
      curated-first trước beta.
- [ ] In scope/out of scope được chốt.
- [ ] Target trong [beta success metrics](beta-success-metrics.md) được duyệt.
- [ ] Privacy/Kids recommendation đã qua người có thẩm quyền.
- [ ] Chỉ khi mọi release gate pass mới chuyển KAN-4/KAN-5 sang Done.

