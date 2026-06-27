# assets/videos

Video "hành trình" đóng gói sẵn cho các vật hero (offline, phát tức thì).

Các file `<id>.mp4` ở đây do script tạo sinh:

```bash
cd proxy && npm run pregen:videos          # tất cả vật hero
cd proxy && npm run pregen:videos -- pencil # chọn vật
```

Script cũng tự thêm `"video": "assets/videos/<id>.mp4"` vào
`app/assets/content/<id>.json`. Sau khi chạy xong: `flutter pub get` rồi build lại.

Vật chưa có file ở đây vẫn xem được video qua AI-live (tạo on-demand khi bấm nút).
