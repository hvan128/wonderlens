# ADR-001: Flutter làm mobile framework

**Status:** Accepted  
**Date:** 2026-06-27

## Context

Cần framework mobile cross-platform (iOS/Android) cho hackathon 1 tuần. Ưu tiên: tốc độ dev, animation đẹp, camera access, 1 codebase.

## Decision

Dùng **Flutter** (Dart).

## Reasons

- 1 codebase → iOS + Android
- Camera plugin trưởng thành (`camera` package)
- Rive/Lottie animation support tốt
- Hot reload → dev nhanh cho hackathon
- Không cần backend Java (constraint)

## Consequences

- Dart (không phải JS/TS) — AI agent cần biết Dart idioms
- Build cần Flutter SDK installed
- Không dùng React Native / Expo
