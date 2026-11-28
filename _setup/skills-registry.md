# Skills registry — InfraBrain

Danh sách skill trong `.claude/skills` (bản gốc ở `_setup/claude/skills`, cài bằng `Install-AgentTeam.ps1`).
Skill lấy từ bên ngoài phải ghi nguồn + commit để biết đang chạy bản nào.

## Skill tự viết

app-release, change-request, fortigate-config-review, incident-rca, pcce-troubleshooting, postgres-ops, vault-ingest, vsphere-health-check

## Skill từ bên ngoài

| Skill | Nguồn | Commit | Ngày cài | Ghi chú |
|---|---|---|---|---|
| handoff | github.com/mattpocock/skills (productivity) | bbadaa6 | 2026-11-28 | **Đã sửa riêng**: lưu vào `95-Agent-Logs/handoffs/`, frontmatter from/to-agent, wikilink, ghi nhật ký agent, cấm secret. Khi cập nhật từ upstream phải merge tay. Chỉ gọi tay `/handoff` |
| grill-me | github.com/mattpocock/skills (productivity) | bbadaa6 | 2026-11-28 | Chỉ gọi tay `/grill-me`, chuyển sang `grilling` |
| grilling | github.com/mattpocock/skills (productivity) | bbadaa6 | 2026-11-28 | Agent tự gọi được khi Đăng muốn "grill" một kế hoạch |
| writing-for-agents | github.com/mattpocock/skills (productivity) | bbadaa6 | 2026-11-28 | Dùng khi viết/sửa skill, CLAUDE.md |
| research | github.com/mattpocock/skills (engineering) | bbadaa6 | 2026-11-28 | Chạy background agent, ghi kết quả có trích nguồn |

Đã review 2026-11-28: chỉ có Markdown + `agents/openai.yaml` (metadata cho Codex), không có script, không gọi mạng, không phụ thuộc `setup-matt-pocock-skills`.

Bản clone gốc: `D:\skills-lab\mattpocock-skills` (máy devmasterpc). Cập nhật: `git pull` → review diff → copy lại → sửa commit ở bảng trên.

## Plugin

| Plugin | Scope | Trạng thái trong vault này |
|---|---|---|
| agent-skills@addy-agent-skills | user | Tắt (`enabledPlugins` trong settings.json) — bộ skill dev, không hợp việc infra |

## Sửa đổi so với upstream

- 2026-11-28: thêm cụm từ kích hoạt tiếng Việt vào `description` của research, grilling, writing-for-agents (giữ nguyên phần tiếng Anh). Khi cập nhật upstream phải giữ lại phần "Tiếng Việt — ...".
- 2026-11-28: handoff viết lại để lưu vào `95-Agent-Logs/handoffs/` (xem bảng trên).
