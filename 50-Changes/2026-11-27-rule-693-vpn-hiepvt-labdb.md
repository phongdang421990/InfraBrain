---
type: change
status: review
updated: 2026-11-27
systems: [FG VDC 10.169.249.90, FG SMB 10.189.110.1, LAB 172.23.90.172]
tags: [network, rule-request, vpn, fsg02, lab]
---
# Rule #693: VPN hiepvt → 172.23.90.172 TCP/5432 (DB unify chat lab test)

Yêu cầu: Quang Bùi Anh nhờ anh Phong mở cho dev (hiepvt). Kiểm tra read-only bởi net-warden ngày 27/11/2026.

## Luồng
| Hop | Thiết bị | Trạng thái | Nguồn |
|---|---|---|---|
| 1 | Client hiepvt, SSL-VPN [[VDC-VNPT]], IP 10.69.68.53, VPNgrp-Development | Đã xác minh (live, firewall auth list) | FG VDC API |
| 2 | FG VDC 10.169.249.90: policy #272 "VPNBase to WAN" ssl.root → wan1, nguồn VPN-BaseBS_10.69.68.0, có VPNgrp-Development, đích FSG2-Zones (⊃ FSG2.Lab_Group ⊃ FSG2.Lab01_172.23.90.0/24), svc ALL, NAT tắt, log tắt | **Đã cho qua**, không cần sửa | FG VDC API |
| 3 | wan1 → RNET-01 10.169.10.99 → IPsec hub → FSG2.R1 210.245.72.172 | Suy luận (selector phải gồm 10.69.68.0/24 ↔ 172.23.90.0/24) | [[FSG02]], [[VDC-VNPT]] |
| 4 | FG SMB 10.189.110.1 (FortiOS 5.6.6) và/hoặc FW-LAB 10.189.14.109 → LAB 172.23.90.0/24 | **Chưa kiểm tra**, đây là nơi nhiều khả năng cần mở | — |
| 5 | Server 172.23.90.172: PostgreSQL listen 5432, pg_hba.conf cho 10.69.68.53 | Chưa kiểm tra | — |

## Việc còn mở
- Đọc policy FG SMB: chiều IPsec (từ VDC) → LAB, đích 172.23.90.172 tcp/5432, nguồn 10.69.68.53 (hoặc dải Dev 10.69.68.32-63); route ngược 10.69.68.0/24.
- Đề xuất nếu thiếu: một policy riêng nguồn 10.69.68.32-63 (hoặc /32 của hiepvt), đích /32, service TCP-5432, log all, comment "#693 hiepvt lab DB", qua skill change-request.
