# TASK-001: Setup & Flutter Skeleton

**Owner:** Dev  
**Status:** Done  
**Branch:** main  
**Ref:** [phase-01-setup-skeleton.md](../plans/2026-06-27-wonderlens/phase-01-setup-skeleton.md)

## Goal

Tạo Flutter project với navigation skeleton, camera screen cơ bản, và Vercel proxy setup.

## Acceptance Criteria

- [ ] Flutter project chạy được trên iOS/Android
- [ ] Camera screen mở được (permission granted)
- [ ] Navigation giữa Camera → Timeline → Collection hoạt động
- [ ] Vercel proxy deploy được (endpoint `/api/recognize` trả 200)
- [ ] `.env` không commit vào repo

## DoD

- `flutter run` không lỗi
- Proxy endpoint reachable
- Code theo ADR-001, ADR-004
- PR merged
