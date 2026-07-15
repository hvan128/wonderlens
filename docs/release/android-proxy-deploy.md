# Deploy Android proxy với Infisical

Runbook production cho Vercel project `wonderlens-android-proxy` và Android
release. Không command nào được in secret value.

## Nguồn secret

| Thuộc tính | Giá trị |
|---|---|
| Infisical project | `shared-platform-secrets` |
| Environment | `prod` |
| Path | `/wonderlens/android-proxy` |
| Keys | `OPENAI_API_KEY`, `APP_SHARED_SECRET` |

`OPENAI_API_KEY` chỉ được nhập trong Infisical. `APP_SHARED_SECRET` được nhúng
vào Android nên chỉ là lớp hạn chế lạm dụng; OpenAI spend limit vẫn bắt buộc.

## 1. Kiểm tra kết nối

```bash
infisical login status
vercel whoami
```

Repo đã link Infisical bằng `.infisical.json`; `proxy/` được link riêng tới
Vercel project bằng file gitignored `proxy/.vercel/project.json`.

## 2. Sync vào Vercel Production

Chạy từ root repo:

```bash
infisical run --env=prod --path=/wonderlens/android-proxy -- bash -ceu '
  : "${OPENAI_API_KEY:?OPENAI_API_KEY missing in Infisical}"
  : "${APP_SHARED_SECRET:?APP_SHARED_SECRET missing in Infisical}"
  cd proxy
  printf %s "$OPENAI_API_KEY" |
    vercel env add OPENAI_API_KEY production --force --sensitive --yes
  printf %s "$APP_SHARED_SECRET" |
    vercel env add APP_SHARED_SECRET production --force --no-sensitive --yes
'
```

Xác minh tên và scope, không đọc value:

```bash
cd proxy
vercel env ls production
```

## 3. Build và deploy proxy

```bash
cd proxy
npm ci
npx tsc --noEmit
vercel build --prod
vercel deploy --prebuilt --prod
```

Production alias phải là
`https://wonderlens-android-proxy.vercel.app`.

## 4. Build Android

Chạy từ root repo:

```bash
infisical run --env=prod --path=/wonderlens/android-proxy \
  --project-config-dir=. -- bash -ceu 'cd app && ./scripts/build-appbundle.sh'
```

Artifact nằm tại `app/build/app/outputs/bundle/release/app-release.aab`.

## 5. Verify tối thiểu

- `/privacy` và `/support` trả `200`.
- GET `/api/recognize` trả `405`.
- POST thiếu `x-app-token` trả `401`.
- POST token đúng nhưng thiếu image trả `400`.
- Một ảnh nhỏ hợp lệ trả đúng JSON contract qua OpenAI.
- AAB có URL proxy mới và không có `OPENAI_API_KEY`.
- `flutter test`, `flutter analyze`, TypeScript check và Vercel build pass.

Khi rotate một trong hai key, chạy lại bước sync, deploy proxy nếu Vercel yêu
cầu, rồi build lại Android nếu `APP_SHARED_SECRET` đổi.
