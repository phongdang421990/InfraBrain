---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "Phiên/agent tiếp theo sẽ làm gì?"
disable-model-invocation: true
---

Viết tài liệu bàn giao tóm tắt cuộc hội thoại hiện tại để một agent mới (context trắng) làm tiếp được.

## Lưu ở đâu

- Lưu vào `95-Agent-Logs/handoffs/` trong vault (tạo thư mục nếu chưa có). Không lưu vào `%TEMP%`.
- Tên file: `YYYY-MM-DD-HHmm-<slug-ngắn>.md`, ví dụ `2026-11-28-1700-vtb-ucrm-pvb.md`.
- Frontmatter:

```yaml
---
type: handoff
date: YYYY-MM-DD
from-agent: <agent đang làm, hoặc "main" nếu là phiên chính>
to-agent: <agent đề xuất làm tiếp, xem _setup/claude/agents/ hoặc bảng routing trong CLAUDE.md>
status: open
tags: [handoff]
---
```

## Nội dung

1. **Mục tiêu**: việc gì, cho khách hàng/hệ thống nào.
2. **Đã làm xong**: gạch đầu dòng, kèm kết quả kiểm chứng.
3. **Đang dở / bước tiếp theo**: theo thứ tự, ghi rõ chỗ nào đang chờ Đăng quyết hoặc gõ "DUYỆT".
4. **Quyết định đã chốt** và **giả định chưa xác minh** (tách riêng hai mục).
5. **Tài liệu liên quan**: dẫn bằng wikilink `[[...]]` tới note, CR, runbook, incident đã có. Không chép lại nội dung đã nằm trong CR/runbook/spec/commit, chỉ trỏ tới.
6. **Skill đề xuất**: agent tiếp theo nên gọi skill nào (ví dụ `change-request` nếu có thay đổi cấu hình, `incident-rca`, `pcce-troubleshooting`...).

Nếu Đăng truyền tham số, coi đó là mô tả việc phiên tiếp theo sẽ tập trung vào và viết tài liệu xoáy vào đó.

## Bảo mật

Vault được sync lên GitHub. Tuyệt đối không ghi mật khẩu, token, API key, private key, hay nội dung đọc từ `99-Secrets/`. Thay bằng `<xem sổ mật khẩu>`.

## Sau khi lưu

- Thêm một dòng vào bảng nhật ký của agent đang làm trong `95-Agent-Logs/<agent>.md` (cột "File đã ghi" là `[[tên-file-handoff]]`, cột cuối ghi "Bàn giao cho <to-agent>"), và cập nhật trường `updated` trong frontmatter của file nhật ký đó.
- Báo Đăng đường dẫn file và agent đề xuất làm tiếp.
