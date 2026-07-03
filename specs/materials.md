# Materials — WonderLens (mạng lưới vật liệu)

> Spec nền cho Trục C/D. Triển khai theo [ADR-012](../adrs/ADR-012-material-graph-model.md).
> Khi đổi schema/danh mục → cập nhật file này + `specs/api-contracts.md` ngay.
>
> **Ghi chú tích hợp:** id vật (`ball_pen`, `paper_a4`, `paper_cup`, `battery_aa`…) khớp
> nhau giữa `hero_catalog.dart`, `assets/content/*.json` và bảng §4 (không cần ánh xạ lại) —
> đã xác nhận qua test `material_catalog_test` trong TASK-017.

## 1. Mục tiêu

Biến "vật liệu" từ một nhãn phẳng thành **mạng lưới sưu tầm**: trẻ phát hiện nhiều đồ vật **chung một vật liệu nguồn** ("bút bi và chai nước đều bắt đầu từ dầu mỏ!") → tăng chiều sâu hiểu biết + động lực sưu tầm.

## 2. Mô hình (graph hai lớp)

```
object ──(materials[])──► material ──(derived_from)──► material(source)
   │                          │
   └── nhiều object chung 1 material = "mạng lưới"
                              └── category (badge thô cũ: Giấy/Nhựa/Kim loại/Gỗ/Thuỷ tinh)
```

- **source**: vật liệu thô (Dầu mỏ, Gỗ, Than chì, Cát).
- **derived**: vật liệu chế biến (Nhựa ← Dầu mỏ; Thép ← quặng sắt; Thuỷ tinh ← Cát; Bột giấy/Giấy ← Gỗ).
- **category**: nhóm tương thích huy hiệu hiện có (không phá vỡ `badges()`).

## 3. Material catalog (bundled — `app/assets/content/materials.json`)

| id | name | emoji | kind | derived_from | category |
|----|------|-------|------|--------------|----------|
| `petroleum` | Dầu mỏ | 🛢️ | source | — | Nhựa |
| `plastic` | Nhựa | 🧴 | derived | petroleum | Nhựa |
| `wood` | Gỗ | 🌳 | source | — | Gỗ |
| `paper_pulp` | Bột giấy | 📜 | derived | wood | Giấy |
| `iron_ore` | Quặng sắt | 🪨 | source | — | Kim loại |
| `steel` | Thép | ⚙️ | derived | iron_ore | Kim loại |
| `graphite` | Than chì | ✏️ | source | — | Kim loại |
| `sand` | Cát | 🏖️ | source | — | Thuỷ tinh |
| `glass` | Thuỷ tinh | 🔍 | derived | sand | Thuỷ tinh |

> Catalog mở rộng dần. `glass`/`sand` có thể **chưa** có hero nào dùng → hiện trạng "chưa khám phá", khuyến khích mở rộng bộ hero (v2).

## 4. Object → materials (gắn vào content JSON từng vật)

| object | materials[] | Ghi chú |
|--------|-------------|---------|
| `ball_pen` | `plastic`, `steel` | vỏ nhựa + viên bi thép |
| `plastic_bottle` | `plastic` | PET từ dầu mỏ |
| `paper_a4` | `paper_pulp` | từ gỗ |
| `paper_cup` | `paper_pulp`, `plastic` | giấy + lớp nhựa mỏng |
| `sticky_note` | `paper_pulp` | giấy + keo (keo chưa làm thẻ riêng) |
| `paper_clip` | `steel` | thép uốn |
| `pencil` | `wood`, `graphite` | thân gỗ + ruột than chì |
| `battery_aa` | `steel` | vỏ kim loại (hoá chất bên trong không làm thẻ) |

> `materials[]` là **optional**: vật thiếu trường này vẫn chạy (app fallback về `material_badge`/`category` cũ).

## 5. Truy vấn graph (runtime, helper `material_catalog.dart`)

- `materialsOf(objectId) → List<Material>`
- `objectsUsing(materialId) → List<heroId>` (chỉ hero; AI-live không vào mạng lưới)
- `sharedMaterials(objectA, objectB) → List<Material>` (nền cho So sánh D8)
- `derivationChain(materialId) → [source … derived]` (nền cho Ghép ngược C2 + thẻ chi tiết)
- `unlockedCards(discoveredIds) → Set<materialId>` (suy ra, không lưu Hive — như `badges()`)

## 6. Unlock & "mạng lưới"

- Khám phá 1 vật → mở thẻ cho **mọi** material trong `materials[]` của vật đó.
- Thẻ chi tiết hiện: blurb + fun_facts + **danh sách vật đã khám phá dùng vật liệu này** (+ số vật chưa khám phá để khơi gợi).
- Thẻ mới mở lần đầu → animation/confetti (tái dùng pattern `newBadge`).

## 7. Business rules

- Chỉ **hero objects** vào mạng lưới (AI-live chưa kiểm chứng — nhất quán với Collection rules).
- Catalog + edge **bundled, offline** — không sinh bằng AI.
- Nội dung thẻ: kid-safe, ngôn ngữ trẻ 6–10, khoa học kiểm chứng (như hero content).
- Đổi danh mục/đồ thị → cập nhật spec này + `api-contracts.md` (AGENTS.md).
