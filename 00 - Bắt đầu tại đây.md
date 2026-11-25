---
type: guide
updated: 2026-11-24
---
# InfraBrain: bắt đầu tại đây

Vault này vừa là **bộ nhớ hệ thống** (Obsidian) vừa là **nơi làm việc của đội agent** (Claude Code). Bạn mở cùng một thư mục bằng cả hai công cụ.

```
InfraBrain/
├── CLAUDE.md              ← "hiến pháp": vai trò, bối cảnh, quy tắc an toàn
├── .claude/agents/        ← 6 agent, mỗi agent có vai trò và tính cách riêng
├── .claude/skills/        ← kỹ năng: quy trình + script mà agent học và dùng lại
├── 00-Inbox … 80-Reports  ← tri thức hệ thống (bạn và agent cùng viết)
├── 90-Raw/                ← log, config, CSV (không đồng bộ lên git)
└── Templates/             ← mẫu note
```

## Bước 1: Mở vault bằng Obsidian
1. Cài Obsidian (obsidian.md).
2. Chọn *Open folder as vault* → `Documents\InfraBrain`.
3. Settings → Core plugins → bật **Templates**, rồi đặt Template folder là `Templates`.

## Bước 2: Cài Claude Code (PowerShell)
```powershell
irm https://claude.ai/install.ps1 | iex
```
Đóng rồi mở lại PowerShell. Cài đội agent và skill (chỉ cần chạy **một lần**; script chỉ copy `_setup\claude` sang `.claude`):
```powershell
cd "$HOME\Documents\InfraBrain"
powershell -ExecutionPolicy Bypass -File .\Install-AgentTeam.ps1
claude
```
Khi muốn sửa agent hoặc skill, sửa trực tiếp trong `.claude\`. Riêng `_setup\` là bản gốc dùng cho các máy khác.
Lần đầu chạy, đăng nhập bằng tài khoản Claude của bạn. Claude Code sẽ tự đọc `CLAUDE.md`, các agent và skill trong `.claude/`.

## Bước 3: Thử đội agent
Gõ trong Claude Code:
- `/agents` để xem danh sách agent
- `Dùng doc-scribe nạp các file trong 00-Inbox vào vault`
- `Dùng infra-sentinel chạy health check vCenter <tên>, rồi viết báo cáo`
- `Sự cố PCCE1 tại FDC lúc 9h sáng nay: dùng rca-tracer và cc-echo phân tích song song các log trong 90-Raw/incidents/...`
- `Hệ thống nào phụ thuộc vào DNS ở FDC?` (hỏi đáp dựa trên vault, đúng kiểu "bộ não thứ 2")

## Bước 4: Nạp tri thức để Claude hiểu hệ thống của bạn
Thả các tài liệu sau vào `00-Inbox/`:
1. Excel bàn giao (145 IP, 13 nhóm hệ thống)
2. Bảng inbound mapping (19 mục)
3. Danh sách 92 câu hỏi rà soát
4. Topology, sơ đồ, tài liệu kiến trúc của khách hàng
5. Config export (mask trước nếu có secret)

Sau đó yêu cầu: `Dùng skill vault-ingest xử lý 00-Inbox`.

## Bước 5: Đồng bộ 3 máy (PC nhà, PC công ty, laptop)
Khuyến nghị dùng **một repo Git private** (GitHub/GitLab), vì có lịch sử thay đổi và quay lại được. `.gitignore` đã loại sẵn `90-Raw/` và `99-Secrets/`.
```powershell
cd "$HOME\Documents\InfraBrain"
git init; git add .; git commit -m "InfraBrain init"
git remote add origin <url-repo-private>; git push -u origin main
```
Trên máy khác: cài Claude Code, `git clone`, rồi mở bằng Obsidian (có thể dùng plugin *Obsidian Git* để tự pull/push).
Trước khi đưa tài liệu khách hàng (ngân hàng) lên cloud, **hãy kiểm tra chính sách bảo mật của BaseBS và của khách hàng**.

## Bước 6: Máy nào làm gì
| Máy | Vai trò |
|---|---|
| PC này | Soạn thảo, phân tích file export, thiết kế, báo cáo |
| PC công ty / jump host | **Nơi agent chạm vào hệ thống thật**: PowerCLI, SSH, psql trong mạng quản trị, chỉ dùng tài khoản read-only |
| Laptop | Đọc và hỏi đáp vault, xử lý sự cố khi đi onsite |

## Quy tắc vàng
- Agent mặc định **chỉ đọc**. Mọi thay đổi đi qua `change-request` và chỉ thực hiện khi bạn gõ **DUYỆT**.
- Bạn tự đăng nhập; **không** lưu mật khẩu trong vault.
- Tạo tài khoản read-only riêng cho agent trên vCenter, FortiGate, DB để mọi thao tác của agent có audit log riêng.
