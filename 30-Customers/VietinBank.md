---
type: customer
status: unverified
updated: 2026-11-26
tags: [customer, bank]
---
# VietinBank (VTB)

## Chủ đề đang làm
- [VAULT] Kiến trúc UCRM giữa PVB và Duy Tân: App HA, PostgreSQL HA, MetroNet, giới hạn tài nguyên.

## Hệ thống / kết nối
*(Bổ sung 2026-11-24 từ [[BaseBS-Infra-Master-Overview]])*

| Hạng mục | Chi tiết | Nguồn |
|---|---|---|
| Site chính | [[FHN01]] (Duy Tân): PCCE3 PROD, 2 host PCCE Cluster03 10.179.110.45 / .47 (BE7H-M5, ESXi 6.5, local disk) | [2N] x11 + rack + BG |
| Dải mạng | 172.31.0.0/16; DNS PROD 172.31.253.51; VoiceGW 172.31.70.11 + PCCE3-VGW-01/02 | [1N] x18 + x14 |
| Thành phần | PCCE (BE7K side A/B), Calabrio, CRM / uCRM v4 (App 172.31.185.51, DB 90.51–53), LCM (DB 90.81–83), SSO 184.53 / .54, MID / Ibox (DB 90.91 / .92), CTI, NLB, Voiceportal, RemoteGW (pcce3basebs.com), Video call, Recording, WFM, Report, replicate AW-HDS / Nifi / DB | [1N] x18 FDCHN-VTB-Prod + x08 |
| UAT | 172.31.245.0/24 (AD .20, GW .1), đặt tại Duy Tân | [2N] x18 Domain + nhóm sheet |
| uCRM v5 (live 2026-11-24) | `VTB_uCRMv5_App01_172.31.185.80` (OL7, 8 vCPU / 8 GB / 60 GB, host .21) + `VTB_uCRMv5_DB01_172.31.90.101` (OL7, 8 vCPU / 16 GB / 600 GB, host .22), đều ở FHN01 A-App Cluster (**không HA**). Đang đánh giá phương án HA với App-2 + Patroni ở PVB: xem [[2026-11-24-ket-noi-FHN01-FHN02-app-db]] | [Live] vCenter Duy Tân |
| CRM v4 PostgreSQL (live từ 06/2026) | Percona/Patroni rút gọn 3 VM (thiết kế gốc 11 VM). Node đã biết `VTB_CRMv4_DB_PG02` 172.31.90.32 (primary theo Ngân); `/` 75.94% (452/595 GiB), tăng ~1.2–1.5 GiB/ngày. Xem [[_VTB-CRMv4-DB]] | Webex CCX-CCE 23/11 + Checkmk |
| Gateway / VLAN (live 24/11) | Gateway mọi dải 172.31.x là **FortiGate External-Primary (FHN1)**. Quy ước VLAN = 200 + octet 3: **PCCE3-DB 172.31.90.0/24 = VLAN 290**, **PCCE3-uCRM 172.31.185.0/24 = VLAN 285**, PCCE3-APP 282, Ext 284, LCM 288, WFM 289, UAT 245… (danh sách đủ: [[FHN01]] mục Network live). VLAN 90/185 là dải 10.179.x của BaseBS, **không phải VTB** | [Live CLI] |
| Uplink VTB trên FHN1.ExtSW | Gi2/0/16 192.168.5.246 (VNPT main), Gi1/0/16 192.168.9.101 (FPT backup), Gi1/0/17 192.168.253.109 (Intercom); tunnel 59/63/65 dùng 5.5.5.x; route ~30 dải VietinCC/DC qua track 353 (FPT) / 354 (VNPT) / Intercom AD 20 | [Live CLI] |
| Public | vcall.connect247.vn 103.35.64.47 → 172.31.183.64; uatwebcall 103.35.64.46 → .245.78 / .94 | [2N] |
| Kết nối riêng | ExtSW FHN01: "MetroVNPT-Vietin-Main", "MetroFPT-Vietin-Backup", "VietinBank-Intercom-Backup" | [1N] x05 PortMap |
| Backup | NFS 10.179.120.5:/VTB_NFSBackup, SMB 10.179.120.6, retention 7 ngày, cùng site | [1N] x08 |
| VDC | 2 address object VietinBank trên FG VDC (chưa rõ vai trò) | [1N] x06 |
| Cloud | Migration PCCE3 lên FPT Cloud (KVM) **đã dừng**; giữ on-premise | [2N] x23 + NOTES |

## Lưu ý
- Quy mô VTB tại [[FHN01]] (live 26/11): 159 VM (96 PROD + 21 PCCE3 + 42 UAT), khoảng 58 TB, khoảng 1,38 TB RAM; riêng ghi âm Calabrio DFS01 / 02 là 31,5 TiB (ổ `E:` 92–94%). Dùng làm số đầu vào khi tính sức chứa PVB.
- **VietinBank ≠ [[VietBank]]** (VietBank là tenant tại [[VDC-VNPT]]).
- ~~IP DB CRM v4 mâu thuẫn~~ **Đã giải (live 24–25/11):** cụm v4 là 172.31.90.31 / .32 / .33. Dải .51–.55 là cụm uCRM cũ (DB02 .52 tắt, DB05 .55 bật). Xem [[_VTB-CRMv4-DB]], [[open-questions]] #19.
- **PCCE3 (live 25/11):** host 10.179.110.45 / .47 tắt dịch vụ NTP, đồng hồ chậm ≈ 25 / 19 phút → [[risk-register]] R-014. Xử lý qua `change-request`, phối hợp `cc-echo`. Chi tiết: [[2026-11-25-vsphere-health-FSG-FHN]].
- "MetroNet PVB ↔ Duy Tân" (mục chủ đề): chưa có cấu hình nào chứng minh. BaseBS trả lời FPT rằng giữa các DC "chỉ có VPN site-to-site" [x21]. Cần làm rõ: đây là thiết kế mới hay đường có sẵn?

## SLA / liên hệ
(bổ sung, không ghi dữ liệu khách hàng nhạy cảm)
