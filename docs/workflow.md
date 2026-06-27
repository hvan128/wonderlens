# Quy trình phát triển phần mềm với AI (Team + Agent)

> **Audience:** Team + AI agent làm việc trong một Git repo.  
> **Mục đích:** Quy trình và nguyên tắc vận hành — **không** mô tả stack hay cấu trúc riêng của từng dự án.  
> **Luật kỹ thuật từng repo:** đọc `AGENTS.md` (hoặc tài liệu tương đương) sau file này.

---

## 0. Đọc trước khi code (agents & developers)

| Thứ tự | Nạp context |
|--------|-------------|
| 1 | File này — quy trình & nguyên tắc |
| 2 | `AGENTS.md` — luật repo (stack, convention, Git…) |
| 3 | `specs/` — what/why/business rules |
| 4 | `adrs/` — how/tech/convention |
| 5 | Task hiện tại — Goal, AC, DoD, owner (`tasks/` hoặc sprint board) |
| 6 | Contracts liên quan — API/event/schema |
| 7 | Chỉ sau đó — đọc/sửa code trong phạm vi task & ownership |

**MUST:** Không code trước khi spec/task có Goal + AC. Không claim done / merge khi chưa DoD (§10). AI sai → sửa **context** trước khi đổi model.

**NEVER:** Push thẳng nhánh chính (`main`) khi chưa review. Code khi thiếu context.

---

## 1. Công thức cốt lõi

```
Context đúng → AI hiểu đúng → Code đúng → Sản phẩm đúng
```

AI **khuếch đại** cách team làm việc — không thay team. Khi AI sai, ưu tiên sửa **context** (spec, ADR, contract, task, `AGENTS.md`) trước khi đổi model.

**Kết quả:** Workflow rõ + context đầy đủ + review chặt → chất lượng + tiến độ ổn định + scale với AI.

---

## 2. Ba trụ + bốn chữ

| Trụ | Thiếu thì |
|-----|-----------|
| Context đầy đủ trong Git | AI đoán, lệch spec |
| Ranh giới rõ (domain + contract) | Không parallel được |
| Quality gate (test + PR + DoD) | “Chạy local” nhưng không ship |

| Chữ | Nghĩa |
|-----|-------|
| **CHIA RÕ** | Domain/module → context nhỏ, ownership rõ |
| **CONTRACT RÕ** | API/event — không phụ thuộc ngầm |
| **TEST RÕ** | Test/AC = đích đến cho AI |
| **DONE RÕ** | Done = đủ chuẩn merge |

---

## 3. Context base (7 phần)

1. **Specs** — what/why/business rules  
2. **ADRs** — how/tech/convention  
3. **Contracts** — giao tiếp giữa phần  
4. **Tasks / plans** — Goal, AC, DoD, owner  
5. **`AGENTS.md`** — luật repo cho AI  
6. **Tests / AC** — hành vi mong đợi  
7. **Git + PR + DoD** — khi được merge  

**Một repo = một nguồn sự thật** — Git lưu cả ý tưởng, quyết định, kế hoạch, không chỉ code.

| Thành phần | Khi cập nhật |
|------------|--------------|
| Specs | Scope / nghiệp vụ đổi |
| ADRs | Stack, pattern, convention đổi |
| Contracts | API, schema, event đổi |
| Tasks & plans | Owner, AC, DoD, trạng thái |
| `AGENTS.md` | Rule bắt buộc mới |

---

## 4. Tám nguyên tắc

1. **Spec-driven** — không code trước khi what/why/how rõ  
2. **ADR là nền** — mọi quyết định kỹ thuật ghi lại; đổi = ADR mới  
3. **Task đủ lớn** — team quản feature; AI chia subtask  
4. **Contract-first** — parallel an toàn  
5. **AI đọc context trước code** — cả team duy trì context  
6. **Git có kỷ luật** — branch + PR, không push thẳng main  
7. **Review & CI** — merge chỉ khi DoD  
8. **Retro liên tục** — context sống, cải tiến bền vững  

---

## 5. Năm ADR nền (cho parallel + AI)

| ADR | Câu chốt |
|-----|----------|
| Test strategy | Test = behavioral contract |
| Domain split | Good domain split = good context split |
| API contract first | Scale by contract, not implicit understanding |
| Structure & convention | Without convention, AI multiplies chaos |
| Definition of Done | Done = meet merge standards, not “runs locally” |

> ADR tốt = Context đủ – Ranh giới rõ – Contract rõ – Test rõ → team + AI làm song song bền vững.

---

## 6. Quy trình macro (sprint)

```
Brainstorm → Specs → Architecture (ADR) → Planning → Parallel execution → Review & merge → Next sprint (retro) → lặp
```

| Bước | Nội dung chính |
|------|----------------|
| **Brainstorm** | Ý tưởng, nhu cầu, mục tiêu đo lường; brainstorm với AI |
| **Specs** | Domains, features, user roles, API contracts, business rules |
| **Architecture** | ADRs, tech stack, kiến trúc, rules, folder structure |
| **Planning** | Backlog, sprint, user stories, **task lớn**, ưu tiên |
| **Parallel execution** | Nhiều dev + AI; commit thường xuyên |
| **Review & merge** | PR, verify, resolve conflict; merge khi DoD |
| **Next sprint** | Retro, cải tiến spec/ADR/quy trình; sprint tiếp theo |

**Nền tảng xuyên suốt:** Git repo shared · Roles rõ · Tools (Git, CI, test, agents, MCP) · Rules (`AGENTS.md`, DoD).

**Thông điệp:** Mọi hoạt động dựa trên **Specs + ADRs + Contracts + Rules**. AI mạnh khi context rõ.

---

## 7. Quy trình micro (mỗi task lớn)

```
Pick task → AI+dev code → Local test → Commit & push → PR & review → Merge
```

| Bước | Chi tiết |
|------|----------|
| 1 **Pick task** | Chọn từ sprint; đọc Goal, AC, DoD, Owner; đọc specs, ADRs, contracts, rules; tạo branch |
| 2 **AI + dev code** | AI: context → plan → subtask → code/test/docs. Dev: giám sát, quyết định. Agent không thay người quyết scope/kiến trúc/merge |
| 3 **Local test** | Unit, integration, lint, build — **chỉ push sau khi pass** |
| 4 **Commit & push** | Commit convention; task → In Review |
| 5 **PR & review** | Linked task, tests, docs, contracts; human và/hoặc AI review |
| 6 **Merge** | Approve → CI → deploy nếu cần → task Done |

**Git (ví dụ):**

```bash
git checkout main && git pull
git checkout -b feature/TASK-002-slug
# ... code + test local ...
git commit -m "TASK-002: mô tả ngắn"
git push origin feature/TASK-002-slug
# Mở PR feature/* → main
```

**Best practices:** Pull latest trước task mới · Commit nhỏ, message rõ · PR bắt buộc · Chỉ merge khi DoD · Tag release khi ship.

```
main          ───●────────●────────●───  (stable)
                  \      /        /
feature/*          ●────●
hotfix/*                    ●─────
```

---

## 8. Parallel execution

**Điều kiện parallel:** Domain split + contract + **file ownership không overlap**.

| Điều kiện | Nếu thiếu |
|-----------|-----------|
| Context đầy đủ trong repo | AI đoán, lệch spec |
| Task đủ lớn, AC/DoD rõ | Micro-manage hoặc AI loop vô hạn |
| Contract giữa domain | Không parallel |
| ADR + convention | Mỗi PR một style |
| Review + CI trước merge | Tech debt tích lũy |

**Ví dụ:** Dev A+AI → Auth · Dev B+AI → Course · Dev C+AI → Lesson — giao tiếp qua contract, không đụng cùng file.

---

## 9. Workspace (Git repo)

**Nguyên tắc:** Một repo — một nguồn sự thật. Team + AI cùng đọc, cùng hiểu, cùng cập nhật.

```
project/
├── specs/                 # product-vision, domains, user-roles, features, api-contracts
├── adrs/                  # quyết định kiến trúc
├── planning/              # backlog, sprints/
├── tasks/                 # task lớn: Goal, AC, DoD, owner
├── src/
├── docs/
├── AGENTS.md
└── README.md
```

| Thư mục | Vai trò |
|---------|---------|
| `specs/` | Spec nghiệp vụ |
| `adrs/` | Quyết định kỹ thuật |
| `planning/` | Backlog, sprint |
| `tasks/` | User story / task lớn |
| `src/` | Code |
| `docs/` | Runbook, how-to |
| `AGENTS.md` | Luật cho AI & team |

**Công cụ:** Git hosting · Task/sprint (Jira, Linear, Issues…) · Docs trong repo · MCP đồng bộ ticket/doc với Git.

---

## 10. Definition of Done (DoD)

Task chỉ **Done** khi:

- [ ] Code đúng spec
- [ ] Test pass (unit / integration / e2e theo ADR)
- [ ] Docs / contracts cập nhật (nếu có thay đổi)
- [ ] Tuân ADR & coding rules / `AGENTS.md`
- [ ] PR reviewed & merged
- [ ] Trạng thái task = Done

**Không merge nếu chưa đủ DoD.**

---

## 11. Vai trò team

| Role | Trách nhiệm |
|------|-------------|
| PM | Ưu tiên, sprint, scope |
| Architect | ADR, quyết định kỹ thuật, contract |
| Dev (+ AI) | Code, tích hợp |
| QA | Test, automation, gate |
| Ops | CI/CD, deploy, monitoring |

---

## 12. Khi AI sai

> **99%** do context chưa đủ hoặc lỗi thời — sửa context trước khi đổi model hay prompt.

1. Task có Goal + AC + DoD đúng không?  
2. Specs & ADRs còn đúng không?  
3. Contract khớp implementation không?  
4. `AGENTS.md` / rules có bị vi phạm không?  
5. Chỉ sau đó xem lại prompt/model.

---

## 13. Checklist nhanh

**Trước task mới:** Spec/task có Goal + AC · ADR liên quan · Contract nếu cross-domain · Ownership rõ · Đã đọc context base.

**Trước PR:** Test + build local pass · Docs/contracts cập nhật · PR checklist · Sync nhánh với remote · Không secret trong diff.

**Cuối sprint:** Retro · Cập nhật spec, ADR, `AGENTS.md` · Backlog sprint sau.

---

## 14. Tóm tắt một trang

```
CÔNG THỨC:  Context đúng → AI hiểu đúng → Code đúng → Sản phẩm đúng

BA TRỤ:      Context Git · Ranh giới domain+contract · Quality gate

BỐN CHỮ:     CHIA RÕ · CONTRACT RÕ · TEST RÕ · DONE RÕ

CONTEXT (7): Specs · ADRs · Contracts · Tasks/plans · AGENTS.md · Tests · Git+PR+DoD

NGUYÊN TẮC:  Spec trước code · ADR nền · Task lớn · Contract-first
             · AI đọc context · Git kỷ luật · Review+CI · Retro

MACRO:       Brainstorm → Spec → ADR → Plan → Execute ∥ → Review → Sprint+ (retro)

MICRO:       Pick → Code (AI+human) → Test local → Push → PR → Merge

SONG SONG:   Domain split + contract + ownership không overlap

5 ADR NỀN:   Test · Domain split · Contract first · Convention · DoD

KHI AI SAI:  Sửa context trước — không đổi model đầu tiên
```

---

*Nội dung cốt lõi đồng bộ [`docs/workflow_dzung.md`](workflow_dzung.md). Cập nhật khi quy trình team thay đổi.*
