# ADR-011 — Dùng `just_audio` cho phát giọng đọc (narration)

- Trạng thái: Accepted
- Ngày: 2026-07-07
- Bối cảnh liên quan: `specs/api-contracts.md` (proxy `/api/speech`), timeline hành trình theo chặng (voice tự đẩy), warm-up giọng đọc (`services/journey_warmup.dart`).

## Bối cảnh

Timeline chiếu **từng chặng full màn**, giọng OpenAI đọc từng đoạn rồi **tự đẩy chặng tiếp**. MP3 giọng đọc đã được **warm-up cache sẵn** từ lúc chụp (log Vercel xác nhận: burst `/api/speech` ngay sau `/api/generate`), nên độ trễ **không** đến từ mạng.

Độ trễ "chờ lâu mới đọc" đến từ **trình phát**: `NarrationService` cũ phát MP3 qua **`video_player`** — mỗi đoạn phải `dispose` controller cũ + `VideoPlayerController.file(...)` + `initialize()`. Trên iOS mỗi lần tạo/khởi tạo controller tốn ~0.5–1.5s ⇒ khoảng lặng đầu mỗi chặng. `video_player` vốn để phát **video**, dùng cho audio-only là sai công cụ.

## Quyết định

Thêm dependency **`just_audio`** và phát giọng đọc bằng nó trong `NarrationService`:

- **Tái sử dụng MỘT `AudioPlayer`** cho cả phiên; đổi đoạn chỉ cần `setFilePath(path)` (nhanh với file local đã cache) → gần như không còn khoảng lặng giữa các chặng.
- Giữ nguyên hợp đồng timeline dựa vào: `speak()` trả về **giống nhau** khi đọc xong tự nhiên (`ProcessingState.completed`) và khi bị `stop()` (hoàn tất `_playDone`).
- Giữ nguyên **fallback giọng máy** (`flutter_tts`) khi offline/lỗi để không bao giờ im.

## Phương án đã cân nhắc

1. **just_audio (chọn)** — công cụ đúng cho audio, `setFilePath`+`play` nhanh, tái dùng player. Đổi lại: +1 dependency.
2. **Look-ahead pre-init trên video_player** (không thêm dep) — pre-init controller đoạn kế khi đoạn hiện tại đang đọc. Không cần dep nhưng phức tạp, đoạn đầu vẫn trễ, và vẫn là công cụ sai.
3. **Giữ nguyên** — độ trễ ~1s/đoạn không chấp nhận được cho app kể chuyện lấy giọng làm trung tâm.

## Hệ quả

- Chuyển chặng gần như tức thì (đã warm-up + player tái dùng).
- `video_player` vẫn dùng cho **phim hành trình** (`journey_video.dart`) — không gỡ.
- iOS dùng Swift Package Manager (xem [[wonderlens-ios-spm-pods]]); `just_audio` hỗ trợ SPM.
- Cần rebuild + verify trên máy thật (debug wireless hỏng → dùng bản release).

## Amendment 2026-07-09: tạm dùng TTS hệ điều hành

Theo yêu cầu owner, app tạm thời ép narration qua TTS mặc định của hệ điều hành
(`flutter_tts`) để phản hồi nhanh hơn và không đợi `/api/speech`.

- Đường OpenAI speech vẫn giữ nguyên trong code (`SpeechService`) để quay lại dễ.
- Công tắc nằm ở `app/lib/services/narration_service.dart`:
  `kUseDeviceTtsOnly = true`. Đổi về `false` để bật lại OpenAI speech khi cần.
- `JourneyWarmup` không prefetch `/api/speech` khi công tắc này bật.

## Amendment 2026-07-09: audio asset Eco88 cho onboarding cố định

Paper cup/onboarding dùng mp3 pre-gen từ Eco88 (`Tuyết Trâm`) trong
`app/assets/audio/`. Timeline ưu tiên `Stage.audio` và cover history theo quy
ước `assets/audio/{object_id}_history.mp3`; file lỗi/missing thì fallback về
`flutter_tts`. Đường OpenAI speech vẫn giữ nguyên sau flag.
