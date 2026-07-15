# TASK-023 — Android production proxy

**Owner:** Hiệp  
**Status:** In progress

## Goal

Tạo một Vercel proxy production mới thuộc tài khoản Hiệp, cấu hình Android
release dùng proxy này, rồi xác minh luồng Android → proxy → OpenAI hoạt động
end-to-end mà không lộ OpenAI API key trong app hoặc repo.

## Acceptance Criteria

- [ ] Vercel project `wonderlens-android-proxy` tồn tại trong scope
      `sireals-projects` và thư mục `proxy/` được link đúng project.
- [ ] Infisical project `shared-platform-secrets`, environment `prod`, path
      `/wonderlens/android-proxy` là nguồn sự thật cho secret production.
- [ ] Production có `OPENAI_API_KEY` và `APP_SHARED_SECRET`; không secret nào
      được commit, ghi vào tài liệu, hoặc in ra log.
- [ ] Request thiếu/sai `x-app-token` nhận `401`; request hợp lệ đi qua OpenAI
      và trả response đúng contract.
- [ ] Android release config dùng URL production mới; iOS release config không
      bị đổi trong task Android này.
- [ ] Android release artifact chứa URL proxy mới, không chứa
      `OPENAI_API_KEY`.
- [ ] `flutter test`, `flutter analyze`, proxy TypeScript check và Vercel build
      đều pass.
- [ ] Production smoke test và runtime error-log check không có lỗi mới.

## Out of scope

- Upload Google Play/TestFlight; bước này cần signing key và store credential.
- Thay đổi API/schema hoặc model hiện có.
- Xoá/chuyển ownership proxy cũ.

## Definition of Done

- [ ] Code/config đúng AC và rules repo.
- [ ] Proxy production mới deploy thành công.
- [ ] Android artifact build thành công với proxy mới.
- [ ] Verification evidence được ghi lại.
- [ ] PR review và merge vào `main`.
