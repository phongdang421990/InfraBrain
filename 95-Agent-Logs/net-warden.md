---
type: agent-log
agent: net-warden
updated: 2026-11-27
tags: [agent-log]
---
# Nhật ký net-warden

| Ngày | Task | File đã đọc | File đã ghi | Kết quả / việc còn mở |
|---|---|---|---|---|
| 2026-11-24 | (ghi bù) CR cách ly 12 file credential khỏi vault, bổ sung .gitignore | 00-Inbox/Base (quét có che secret) | [[2026-11-24-quarantine-credential-files]], .gitignore | Done; còn rotate credential (R-007) |
| 2026-11-27 | Kiểm tra rule #693 VPN hiepvt → 172.23.90.172 tcp/5432 | FSG02, VDC-VNPT, FG VDC live API | [[2026-11-27-rule-693-vpn-hiepvt-labdb]] | FG VDC đã cho qua (#272); còn mở FG SMB/FW-LAB + pg_hba |
