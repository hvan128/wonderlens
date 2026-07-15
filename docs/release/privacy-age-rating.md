# Privacy, age rating và Kids/Family decision

**Jira:** [KAN-31](https://aichoem.atlassian.net/browse/KAN-31)  
**Owner:** Hoàng Hiệp  
**Trạng thái:** Recommendation chờ PM + legal sign-off  
**Cập nhật chính sách:** 2026-07-15

> Đây là checklist sản phẩm/release, không phải tư vấn pháp lý. Những kết luận
> về COPPA, luật Việt Nam hoặc thị trường phát hành phải được người có thẩm
> quyền duyệt trước submit.

## Recommendation

### Apple v1

- **Không chọn Kids Category cho build hiện tại.** Định vị store là app gia đình
  để phụ huynh dùng cùng con.
- Vẫn xử lý sản phẩm như child-directed: không ads/tracking, data minimization,
  parent supervision, safety review và khai báo ảnh chính xác.
- Điền age-rating questionnaire theo capability thật; với nội dung hiện tại,
  kết quả kỳ vọng là mức thấp nhất phù hợp (thường 4+), nhưng không hardcode kết
  quả trước khi App Store Connect tính.
- Không dùng “For Kids/For Children” trong metadata nếu không ở Kids Category.

Lý do chưa vào Kids Category:

1. Legal links trong `ProfileScreen` mở trình duyệt ngoài và chưa có parental
   gate; Apple yêu cầu link/purchase/distraction trong Kids app nằm sau gate.
2. Purchase có phép tính parent gate, nhưng toàn bộ đường ra ngoài/IAP cần audit
   trên build thật, không chỉ một dialog.
3. Ảnh camera được gửi tới OpenAI; default abuse-monitoring có thể giữ dữ liệu
   tối đa 30 ngày. Cần legal đánh giá việc truyền ảnh có thể chứa mặt/PII của trẻ.
4. Runtime red-team AI-live chưa có bằng chứng pass.
5. Sau khi app Kids Category được duyệt, Apple nêu rõ lựa chọn đó không thể đơn
   giản bỏ ở update sau; đây là quyết định dài hạn.

### Google Play v1

- **Không khai 18+ only.** PRD, UI, copy và visual rõ ràng hướng trẻ 6–10, nên
  khai audience thật: `Ages 6–8`, `Ages 9–12` và người lớn nếu console cho phép
  chọn nhóm đồng sử dụng phù hợp.
- Việc chọn nhóm có trẻ kích hoạt Families Policy. Build chỉ được lên closed/
  production sau khi privacy, APIs, data safety, IAP gate và AI content policy
  được audit.
- Không ads, không analytics SDK, không AAID là hướng đúng; vẫn phải khai camera
  photo transmission và generative-AI safety/feedback path chính xác.

Google cảnh báo metadata/visual hấp dẫn trẻ có thể ảnh hưởng đánh giá audience
dù console khai khác. Vì vậy “18+ nhưng app cho bé” là rủi ro misrepresentation,
không phải đường tắt policy.

## Apple: App Privacy đề xuất

| Câu hỏi | Đề xuất | Căn cứ |
|---|---|---|
| Privacy Policy URL | `https://wonderlens-proxy.vercel.app/privacy` | Đang live trong repo/report |
| Collect data? | Yes | Ảnh đi off-device và OpenAI có thể giữ abuse logs > thời gian real-time |
| Data type | Photos or Videos | Camera photo |
| Purpose | App Functionality | Nhận diện + sinh journey/media |
| Linked to identity | No | Không account/user ID; phải giữ đúng trong code |
| Tracking | No | Không ads/cross-app tracking |

Apple định nghĩa “collect” dựa trên thời gian developer/third party có thể truy
cập dữ liệu lâu hơn thời gian cần để phục vụ request. Vì OpenAI công bố default
abuse-monitoring retention tối đa 30 ngày, không nên chọn “No data collected”
trừ khi tổ chức đã được duyệt Zero Data Retention, cấu hình đúng project/endpoint
và legal xác nhận disclosure mới.

## Google Play: Data safety đề xuất

| Câu hỏi | Đề xuất hiện tại | Gate |
|---|---|---|
| Collect/share required data? | Yes | Ảnh truyền off-device |
| Data type | Photos and videos → Photos | Chỉ user-triggered camera photo |
| Collected | Yes | Theo định nghĩa Google |
| Shared | No, chỉ nếu OpenAI là service provider xử lý thay developer | Legal/DPA xác nhận |
| Processed ephemerally | **No** ở cấu hình mặc định | OpenAI có thể giữ logs tối đa 30 ngày |
| Required/optional | Optional | User chủ động chọn chụp; app không có core online nếu không chụp |
| Purpose | App functionality | Không analytics/ads |
| Encrypted in transit | Yes | HTTPS; cần verify mọi endpoint |
| Deletion | Mô tả local delete + provider retention/contact | Policy/console wording phải khớp |

Google định nghĩa ephemeral là chỉ ở memory và không giữ lâu hơn request
real-time. Retention 30 ngày không đạt định nghĩa đó. Báo cáo console cũ trong
`plans/reports/` ghi ephemeral `Yes`; cần sửa trước submit.

## Age rating khác Kids Category

| Khái niệm | Nó trả lời gì? | WonderLens |
|---|---|---|
| Apple age rating | Nội dung/capability phù hợp độ tuổi nào | Điền questionnaire; kỳ vọng mức thấp |
| Apple Kids Category | Có tham gia khu app thiết kế riêng cho trẻ và ràng buộc dài hạn không | Recommendation: chưa ở v1 |
| Google content rating | Mức nội dung theo IARC | Kỳ vọng Everyone/3+ khi trả lời đúng |
| Google target audience | App thực sự thiết kế cho nhóm tuổi nào | 6–8, 9–12, đồng sử dụng với người lớn |
| COPPA/law | Nghĩa vụ pháp lý khi dịch vụ hướng/biết đang xử lý dữ liệu trẻ | Legal phải đánh giá riêng |

Không dùng rating thấp làm bằng chứng đã tuân thủ privacy law. Apple cũng nêu
parental gate không đồng nghĩa verifiable parental consent theo luật.

## Audit build trước submit

### Data flow

- [ ] Flutter chỉ gửi ảnh khi user tap shutter và đã cấp camera permission.
- [ ] Không log base64, prompt chứa ảnh hoặc response PII ở app/proxy.
- [ ] Proxy không lưu body vào DB/blob/cache; kiểm tra Vercel logging config.
- [ ] OpenAI organization/project training opt-out mặc định được xác nhận.
- [ ] Retention mode thực tế (default/MAM/ZDR) được release owner ghi lại.
- [ ] Privacy policy nêu OpenAI, mục đích, retention, security, deletion/contact.
- [ ] Không chụp khuôn mặt/giấy tờ được nhắc ngay cạnh camera, không chỉ policy.

### Child/family UX

- [ ] External links và purchase path được audit parental gate end-to-end.
- [ ] Không ads, analytics, AAID, social profile, chat hoặc public child content.
- [ ] AI-live có nhãn và error/report path phù hợp Google AI content policy.
- [ ] Red-team safety pass, zero critical.
- [ ] Store metadata không mâu thuẫn target audience declaration.

### Legal/operations

- [ ] Data controller/legal entity và privacy contact khớp store listing.
- [ ] DPA/terms với OpenAI và hosting được lưu ngoài repo đúng nơi quản trị.
- [ ] Legal đánh giá COPPA và luật của từng thị trường phát hành.
- [ ] Có quy trình trả lời privacy/deletion request của phụ huynh.
- [ ] PM + legal ký tên/ngày/phiên bản build trong release checklist.

## Nội dung parent-facing tối thiểu

Tại camera, trước hoặc gần lần chụp đầu:

> WonderLens gửi ảnh đồ vật tới dịch vụ AI để kể hành trình. Bố mẹ hãy đồng hành
> và tránh chụp khuôn mặt, giấy tờ hoặc thông tin cá nhân.

Tại privacy summary:

> Không tài khoản, quảng cáo hay tracking. Nhật ký nằm trên thiết bị. Ảnh chụp
> đi qua máy chủ WonderLens tới OpenAI; máy chủ WonderLens không lưu ảnh, còn
> OpenAI có thể giữ dữ liệu API tối đa 30 ngày để giám sát lạm dụng.

## Nguồn chính thức

- [Apple App Review Guidelines — Kids và Privacy](https://developer.apple.com/app-store/review/guidelines/)
- [Apple App information — age rating và Made for Kids](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Apple: Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Google Play Families / Developer Program Policy](https://support.google.com/googleplay/android-developer/answer/17105854?hl=en)
- [Google target audience and content](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en)
- [Google Data safety definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Google AI-generated content policy](https://support.google.com/googleplay/android-developer/answer/14094294?hl=en)
- [FTC Children’s Privacy / COPPA guidance](https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy)
- [OpenAI API data controls and retention](https://platform.openai.com/docs/models/default-usage-policies-by-endpoint)

## Sign-off

| Vai trò | Người | Quyết định | Ngày/build |
|---|---|---|---|
| PM | Chưa điền | Pending | — |
| Legal/privacy | Chưa điền | Pending | — |
| Tech/release | Chưa điền | Pending | — |

