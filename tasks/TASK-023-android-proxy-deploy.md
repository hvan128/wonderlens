# TASK-023 — Android development proxy

**Owner:** Hiệp  
**Status:** Ready for review — dev deployment live

## Goal

Tạo một Vercel proxy thuộc tài khoản Hiệp, cấu hình Android development dùng
stable Production alias của proxy này, rồi xác minh luồng Android → proxy →
OpenAI hoạt động end-to-end mà không lộ OpenAI API key trong app hoặc repo.

> Deployment hiện chỉ dùng để development theo quyết định ngày 2026-07-15.
> Không coi AAB ký debug là bản phát hành Google Play.

## Acceptance Criteria

- [x] Vercel project `wonderlens-android-proxy` tồn tại trong scope
      `sireals-projects` và thư mục `proxy/` được link đúng project.
- [x] Infisical project `shared-platform-secrets`, environment `prod`, path
      `/wonderlens/android-proxy` là nguồn sự thật cho secret production.
- [x] Production có `OPENAI_API_KEY` và `APP_SHARED_SECRET`; không secret nào
      được commit, ghi vào tài liệu, hoặc in ra log.
- [x] Request thiếu/sai `x-app-token` nhận `401`; request hợp lệ đi qua OpenAI
      và trả response đúng contract.
- [x] Android release config dùng URL production mới; iOS release config không
      bị đổi trong task Android này.
- [x] Android release artifact chứa URL proxy mới, không chứa
      `OPENAI_API_KEY`.
- [x] `flutter test`, `flutter analyze`, proxy TypeScript check và Vercel build
      đều pass.
- [x] Production smoke test và runtime error-log check không có lỗi mới.

## Verification evidence — 2026-07-15

- Vercel deployment `dpl_GuVkCQmPVUfxPQi1j9BiCMBbRdZf`: `READY`, alias
  `https://wonderlens-android-proxy.vercel.app`.
- `/privacy` và `/support`: `200`; GET `/api/recognize`: `405`; POST thiếu
  token: `401`; token đúng + thiếu ảnh: `400`.
- OpenAI thật: `/api/recognize` trả `ball_pen`, confidence `0.95`, source
  `openai`; `/api/generate` trả `Bút bi`, 4 chặng, source `live`.
- Vercel error log và `5xx` log trong 30 phút: không có record.
- AAB: `96,752,059` bytes, SHA-256
  `38cf49cb49f3f2080724498d08860969eaa95e18524740d6fb67a72967345896`.
  Artifact có URL mới; không có `OPENAI_API_KEY`, `sk-*`, hoặc fallback token.
- AAB ký `Android Debug`; `android/key.properties` chưa có nên artifact chỉ
  dùng test/dev, không upload Google Play.
- `flutter test`: 92 pass; `flutter analyze`: 0 issue; TypeScript: pass;
  Vercel build: pass; production npm audit: 0 vulnerability.

## Out of scope

- Upload Google Play/TestFlight; bước này cần signing key và store credential.
- Thay đổi API/schema hoặc model hiện có.
- Xoá/chuyển ownership proxy cũ.

## Definition of Done

- [x] Code/config đúng AC và rules repo.
- [x] Proxy production mới deploy thành công.
- [x] Android artifact build thành công với proxy mới.
- [x] Verification evidence được ghi lại.
- [ ] PR review và merge vào `main`.
