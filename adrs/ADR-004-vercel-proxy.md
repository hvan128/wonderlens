# ADR-004: Vercel serverless proxy giấu API key

**Status:** Accepted  
**Date:** 2026-06-27

## Context

Không được để API key trong app (lộ key). Cần layer trung gian giữa app và OpenAI.

## Decision

**Vercel serverless functions** (`/proxy/api/`) làm proxy layer.

## Reasons

- Giấu `OPENAI_API_KEY` trong Vercel env vars
- Deploy free tier đủ cho hackathon
- Vercel CLI deploy nhanh
- Có thể cache response (tránh gọi lặp)
- Không cần setup server riêng

## Consequences

- Live AI features cần internet đến Vercel
- Thêm ~100-200ms latency (proxy hop)
- Cần Vercel account + CLI
- Key rotation: thay trong Vercel dashboard, không deploy lại app
