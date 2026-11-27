---
type: customer
status: unverified
updated: 2026-11-27
tags: [customer, cloud, aicc]
---
# Heineken — AICC trên CMC Cloud

Nguồn: x09 (sheet CMC Cloud, bản trích lại 24/11) + NOTES / BRIEF. Chi tiết ở [[BaseBS-Infra-Master-Overview]] §3.7.

| VM / hostname | Vai trò | OS | IP |
|---|---|---|---|
| ecs-aiapp01-52 | AICC App Callbot | Debian 12.14 [đã xác minh 27/11] | 192.168.182.52 |
| ecs-aidb01-52 | AICC Database Callbot | Oracle Linux 8.10 | 192.168.90.52 |
| ecs-proxy01-51 | AICC App Proxy | OL 8.10 | 192.168.184.51 |
| ecs-lcmapp01-51 | BASE LCM App | Windows Server 2019 | 192.168.188.51 |
| ecs-vportal01-52 | Voiceportal | OL 8.10 | 192.168.188.52 |
| ecs-voicegw01-11 | Voice gateway | Cisco IOS | 192.168.70.11 |
| ecs-ssoapp01-51 | SSO App | Windows Server 2019 | 192.168.182.51 |
| ecs-ssoelastic-61 | SSO Elasticsearch | OL 8.10 | 192.168.182.61 |
| ecs-mongodb01-51 | SSO MongoDB + Redis node 1 | OL 8.10 | 192.168.90.51 |
| (tên bị che, xem [[BaseBS-Infra-Master-Overview]] §1.3) | Monitoring | OL 8.10 | 192.168.120.55 |
| ecs-pfsense | Firewall / GW, pfSense CE 2.7.0, GUI :8443 | — | 192.168.{70,90,120,182,184,188}.254 |

- Tất cả ở trạng thái Active [1N x09].
- Mâu thuẫn IP DB (C07) đã giải quyết: aidb01 = .90.52, mongodb01 = .90.51.
- [SL] Mỗi vai trò chỉ có 1 node (không HA).
- Credential portal CMC có OTP: lưu ở password manager.

## AICC (đã xác minh 2026-11-27, nâng cấp [[2026-11-27-hnk-aicc-1.0.11-upgrade]])
- Phiên bản: **1.0.11** (gói ai-callcenter, BasePath `/ai-callcenter`), từ 1.0.8, ngày 2026-11-27. Source cũ giữ ở `/opt/voicebot-publish.bk1.0.8` (còn `.bk1.0.6`, `.bk1.0.7`).
- App `/opt/voicebot-publish`, unit `aicc.service` (User=voicebot, ProtectSystem=strict) + drop-in `aicc.service.d/10-json-cdr.conf`.
- FreeSWITCH chạy cùng máy App; SIP profile/gateway do AICC cấp qua xml_curl `:5000/fs/*`; trunk ra VoiceGW 192.168.70.11. `mod_json_cdr` bật, log-dir `/var/lib/freeswitch/json_cdr`.
- DB: PostgreSQL 17.9 trên ecs-aidb01-52, DB `voicebot_db` chủ `voicebot_user`. Chạy SQL không cần mật khẩu: `su - postgres` + `PGOPTIONS='-c role=voicebot_user'` (để object thuộc user app). Máy App không có psql/rsync.
- Còn mở: media_timeout + xoá sip_profiles (HD 1.0.10 §4.2–4.3) chờ anh Kiệt; quyền Third party → View cho role agent (team khác cấu hình).

## Cần xác minh
- Ingress public / NAT trên pfSense; SIP trunk của VoiceGW.
- Backup VM trên CMC; trách nhiệm chia sẻ với CMC.

## SLA / liên hệ
(bổ sung)
