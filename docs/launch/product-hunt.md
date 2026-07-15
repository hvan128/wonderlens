# Product Hunt launch preparation

**Jira:** [KAN-41](https://aichoem.atlassian.net/browse/KAN-41)  
**Owner:** Hoàng Hiệp  
**Trạng thái:** Draft; chưa đủ launch gate  
**Cập nhật:** 2026-07-15

## Timing decision

Không launch Product Hunt trước khi:

- Android internal/closed beta pass core QA.
- Runtime safety set không có critical failure.
- Privacy/target audience/store declarations được duyệt.
- Landing/waitlist live, submit/delete path đã test.
- Camera → result → timeline demo và gallery phản ánh build thật.
- Một founder/maker cam kết trực launch và trả lời bằng giọng của họ.

Product Hunt nêu sản phẩm được feature nên sẵn sàng để dùng hoặc có đường launch
rõ. WonderLens hiện ở bước chuẩn bị closed beta, nên chỉ tạo draft.

## Draft fields

| Field | Draft |
|---|---|
| Name | `WonderLens` |
| Tagline | `Turn everyday objects into STEM stories for families` |
| Description | `WonderLens helps parents and children photograph an everyday object and explore how it was made through short Vietnamese visual stories, narration, and an on-device discovery collection.` |
| Website | `[waitlist live URL — pending]` |
| Topics | Education, Artificial Intelligence, Parenting, Android |
| Pricing | Free beta; không hứa pricing production |
| Promo | None |
| Makers | `[Product Hunt usernames — founder điền]` |

Description phải được kiểm tra ≤260 characters ở form thật. Không thêm “for
kids” như store category claim; nhấn mạnh parent co-use.

## Gallery plan

| Slot | Asset | Trạng thái |
|---:|---|---|
| 1 | 30–45s camera → reveal → timeline demo | Missing recording từ final beta build |
| 2 | Camera screenshot + value headline | Missing |
| 3 | `app/store-assets/screenshots/65_05-result.png` | Có result + AI label |
| 4 | `app/store-assets/screenshots/65_03-collection.png` | Có |
| 5 | `app/store-assets/screenshots/65_06-timeline.png` | Có; PM review frame/copy |
| Logo | `app/store-assets/play-icon-512.png` | Có |

Promo video hiện có ở `promo/wonderlens-promo/wonderlens-promo.mp4`, nhưng maker
phải xác nhận nó khớp build và đúng tỉ lệ/độ dài trước upload.

## Maker/first comment

Product Hunt hiện yêu cầu tương tác person-to-person và hướng dẫn tránh comment
do LLM tạo. Vì tài liệu này được AI hỗ trợ, **không paste một maker comment sinh
sẵn**. Maker phải viết lại bằng trải nghiệm và giọng thật của mình theo worksheet:

1. Tôi là ai và vì sao câu hỏi của trẻ về đồ vật khiến tôi bắt đầu WonderLens?
2. Khoảnh khắc đầu tiên camera → journey hoạt động trên máy thật là gì?
3. Trade-off khó nhất: freedom của AI-live hay curated safety/tốc độ?
4. WonderLens chủ động không xây gì cho trẻ (account/ads/social profile)?
5. Beta hiện làm được gì, chưa làm được gì?
6. Hôm nay maker muốn cộng đồng thử/góp ý đúng một điều gì?
7. Cảm ơn cụ thể team/tester nào — chỉ ghi tên khi được đồng ý.

**First-comment gate:** founder tự viết, PM kiểm chứng claim, privacy reviewer
duyệt dữ liệu/child wording. Đây là external human-authorship dependency, không
thể tự động đánh dấu Done.

## FAQ dùng cho launch replies

### Is WonderLens a kids app?

It is designed for parents to use together with children ages six to ten. It
does not provide child accounts, public profiles, ads, or tracking.

### What happens to a photo?

The app sends it through a WonderLens relay to OpenAI to generate the journey.
The WonderLens server does not store the photo; OpenAI may retain API content
for up to 30 days for abuse monitoring under default controls.

### Is every story verified?

No. Curated stories receive more review; AI-generated journeys are labeled and
can be wrong. Safety and factual QA are release gates, not perfect guarantees.

### Does it work offline?

Saved/curated journeys and local collection data can work offline. The current
production camera flow needs a network connection to generate a new journey.

### Why Vietnamese first?

The product focuses on short, readable Vietnamese stories for local families
before expanding languages or curriculum breadth.

### How is it different from visual search?

The core output is not just an object label. It is a parent-child STEM story
about materials and manufacturing, with narration and a local collection.

### Can teachers use it?

Teacher pilots should start with reviewed curated content. Classroom/admin
features are not in the current beta.

## Pre-launch checklist

### Product and trust

- [ ] Closed beta build link works for target devices.
- [ ] Core QA and safety gates pass with evidence.
- [ ] Privacy, AI label and family positioning are consistent everywhere.
- [ ] Waitlist submit/unsubscribe/delete works.
- [ ] Support owner and incident escalation are on call.

### Product Hunt draft

- [ ] Name, tagline, description, topics, website entered.
- [ ] Maker usernames joined and profiles complete.
- [ ] Gallery/video uploaded and previewed.
- [ ] Founder authored first comment; PM/privacy reviewed.
- [ ] Launch date/time confirmed in Product Hunt dashboard. Official help says
      scheduled launches use 12:01 AM PST; verify timezone/daylight behavior.

### Launch-day roles

| Role | Owner | Duty |
|---|---|---|
| Launch commander | Founder/PM — pending | Go/no-go, dashboard, incidents |
| Product Hunt maker | Pending | Publish human first comment, answer questions |
| Technical responder | Dev — pending | Bugs, architecture, live status |
| Safety/privacy responder | Pending | Accurate data/child/AI answers |
| Social owner | Hoàng Hiệp | Cross-post direct link, measure |
| Support backup | Pending | Inbox/waitlist issues |

Không lập “upvote squad”, mass comment hoặc AI-generated reply. Chia sẻ direct
link là được; yêu cầu supporter dùng thử và phản hồi thật, không thao túng vote.

## Launch-day runbook

| Mốc | Việc |
|---|---|
| T-24h | Re-run smoke test; freeze copy/assets; verify waitlist/support |
| T-2h | Owners online; status page/log access; final go/no-go |
| Live | Founder posts human comment; Hiệp cross-posts direct link |
| +1h | Triage questions/bugs; pin factual clarifications if needed |
| +4h | Check waitlist errors, reply to substantive comments |
| +8h | Team handoff; no unanswered privacy/safety question |
| +24h | Thank community, publish known issues honestly |
| +7d | Metrics + learning review; no vanity-only report |

## Metrics

| Metric | Source | Interpretation |
|---|---|---|
| Product page visits | Product Hunt | Reach |
| Upvotes/rank | Product Hunt | Visibility, not PMF |
| Meaningful comments | Manual | Question/feedback quality |
| Website clicks | Product Hunt/aggregate landing | Intent |
| Adult waitlist signups | Approved CRM | Qualified interest |
| Beta invites accepted | Store track | Funnel progress |
| First successful journey | Manual beta | Activation |
| Safety/support incidents | QA/support | Release health |

Post-launch report phải có conversion denominator và ghi rõ sample size.

## Official Product Hunt references

- [How to post a product](https://help.producthunt.com/en/articles/479557-how-to-post-a-product)
- [Getting started](https://help.producthunt.com/en/articles/2305333-getting-started)
- [Commenting guidelines](https://help.producthunt.com/en/articles/10030102-commenting-guidelines)
- [Featuring guidelines](https://help.producthunt.com/en/articles/9883485-product-hunt-featuring-guidelines)

## Approval

- [ ] PM/founder approves timing and checklist.
- [ ] Founder supplies maker usernames and human-authored first comment.
- [ ] Privacy/safety owner approves FAQ.
- [ ] All launch gates pass; only then schedule.
