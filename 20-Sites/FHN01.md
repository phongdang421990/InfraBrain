---
type: site
status: unverified
updated: 2026-11-24
tags: [site, fpt, hanoi, basebs, pcce3]
---
# FHN01 — FPT Duy Tân, Hà Nội (rack CG3-i5)

Thuộc [[FDC-FPT]]. Báo cáo tổng: [[BaseBS-Infra-Master-Overview]] §3.4. IP chi tiết: [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục D.

## Thông tin site
| Mục | Giá trị | Nguồn |
|---|---|---|
| Mã | FHN01 / "FDC HN01" / FDCHN | [2N] |
| Rack | FDC-DuyTan-CGY-CG3-i5 (47U) | [2N] x13 + BG |
| Public | FHN1.R1 103.35.64.45 (peer IPsec VDC); NAT 103.35.64.46/.47 qua loopback A-CCX 10.179.11.101/.102 | [2N] x06 + x18 |
| Metro | ExtSW Po24 MetroFPT: VLAN 1009 TPBank, 1010 Vinacis, 1018 MBAL, 1082 HDSS. Port: Lotte P2P/Metro, **VietinBank Metro VNPT (main) / FPT (backup)**, FPT iVoice-HDSS | [1N] x05 |

## Network
| Thiết bị | Model | IP | Nhãn |
|---|---|---|---|
| RNET-01 / 02 | ISR4331-SEC (BG) / ISR4431-SEC (DeviceList) | 10.179.10.99 / **.102** (BG) hoặc .101 (DeviceList) | [1N] mâu thuẫn K11 |
| FortiGate 01 / 02 | FG-201E (serial …18901932 / …18903181) | 10.179.249.90 / .91 | [2N] |
| ExtSW | 2× C3850-24T-E | 10.179.20.234 | [2N] |
| IntSW | 2× C3850-48T-S stack | 10.179.110.20 | [2N] |
| VoiceGW | ISR4331-V 10.179.70.11 / .12; PCCE3-VGW-01/02 (ISR4331, chưa có IP); 172.31.70.11 | | [2N] |
| SAN SW | DS-300B / D6500 | 10.179.110.5 / .6 | [2N] |

Default route của ExtSW → FW 10.179.20.123 [1N x05].

## ESXi / vCenter
vCenter 10.179.110.10 [1N]. ESXi 6.5 [2N x11 + BG + rack].

**Live 2026-11-24** (vCenter UI, read-only, xem [[2026-11-24-ket-noi-FHN01-FHN02-app-db]]):
- vcsa.ccxbasebs.com **6.5.0 b24045034**, datacenter FDCHN, **9 host / 201 VM**.
- Tổng: RAM 1.69 / 2.58 TB (66%), storage 69.96 / 91.21 TB (77%), CPU 12%.
- **A-App Cluster (6 host .21–.26): vSphere HA OFF, DRS OFF, EVC Disabled.** Host chết thì VM không tự khởi động lại. RAM 70% (1.48 / 2.12 TB), storage 83%. RAM từng host 62–74%.
- PCCE Cluster03: .45 (RAM 48%), .47 (43%, **Alert**). A-CCX Cluster: .53 (36%, uptime 2870 ngày).
- 🔴 **Host .47 (PCCE3-B): alarm "Host hardware fan status" CRITICAL từ 19/12/2024**, đã bị ack ngày 13/06/2025 bởi `CCXBASEBS\vinhlq`, nên đang bị ẩn.
- Datastore CRITICAL: **Cust_SAN.BK 91%** (còn 4.39 / 49.53 TB, alarm từ 12/01/2026), **Cust_SVR.01 86%** (còn 2.16 / 15 TB, alarm từ 19/11/2026). Infra_SVR.01 49%. SvrApp.0x-Local là local disk của từng host. [Live]

| Cluster | Host |
|---|---|
| A-App | .21 R660xs, .22 / .23 / .26 R640, .24 R650xs (BG ghi R660XS), .25 R650xs |
| PCCE Cluster03 | .45 PCCE3-A / .47 PCCE3-B (BE7H-M5, local disk, đĩa hỏng nhiều lần) |
| A-CCX | .53 BE7M-M5 |

## Storage
- Unity300 CKM00184201856, 10.179.110.9.
- Raw: theo StorageInfo ≈ 110 TB (có expansion 6 TB); theo DeviceList ít hơn.
- **Lỗi đĩa 2024–2025, slot 12 chưa có đĩa thay** [2N x14 + x17].

## Khách hàng / dịch vụ
- **[[VietinBank]]**:
  - PCCE3 PROD và VTB UAT 172.31.245.0/24.
  - vcall / uatwebcall.
  - uCRM 172.31.185.51 / DB 90.51–53; LCM; SSO 184.53 / .54; MID / Ibox; Recording, WFM, Report.
  - Nguồn: [2N] x18 + x08.
- Connect247 standby: App 186.51 / .52, DB 90.51 / .52, Interact, Agent, LB 186.61 / .62, Voice 186.65–67, Autocall 186.71–76, Kamailio LB 184.71 / .72.
- TPBank LCM (188.51 / .52, DB 90.81–83); Lotte (Calabrio Recording, Voicegw, Asterisk).
- BASE_Central_logs 184.41, Proxy_Mgt 184.42.
- AD CN247 10.179.120.20; RemoteGW pcce3basebs.com (DB 172.31.184.56).
- Backup: 10.179.120.5 / .6 (VTB), 10.179.80.5 / .6 (TPB / Lotte / CN247).

## Rủi ro
- ESXi 6.5; Unity300 hỏng đĩa liên tục.
- PCCE3 chạy local disk, không có HA phần cứng; PCCE3 không chuyển lên cloud được (x23).
- FortiOS 5.6.6.

## Cần xác minh
- Model và IP RNET-02 (K11, K10).
- ~~Mạng PCCE3 172.31.x có FW / router riêng không.~~ **Đã trả lời 2026-11-24:** gateway 172.31.x là FortiGate External-Primary (xem mục Network live).
- "MetroNet PVB ↔ Duy Tân" trong [[VietinBank]]: BaseBS khai với FPT là "chỉ có VPN site-to-site" (x21).

## Network live (CLI chủ vault chạy, 2026-11-24)
Nguồn: `show ip interface brief`, `show vlan brief`, `show running-config | include ip route`, `show ip arp vlan 20` trên FHN1.ExtSW; `show system interface`, `get system ha status` trên FortiGate. Inventory x05 sai nhiều chỗ → **lấy mục này làm nguồn chuẩn**.

### FHN1.ExtSW (2× C3850-24T stack)
| Interface | IP | Vai trò |
|---|---|---|
| Vlan20 (FW-EXT) | 10.179.20.234/24 | Quản trị + next-hop tới FortiGate 10.179.20.123 |
| Vlan1009 / 1010 / 1018 / 1082 | 172.16.251.157 / 10.179.252.17 / 172.16.86.30 / 192.168.100.51 | Metro FPT: TPBank / Vinacis / MBAL / HDSS |
| Gi1/0/13 / Gi2/0/13 (routed) | 10.252.19.174 / 10.252.19.170 | Lotte FPT (track 351, peer .173) / Lotte VNPT (peer .169, AD 10) |
| Gi2/0/16 / Gi1/0/16 / Gi1/0/17 (routed) | 192.168.5.246 / 192.168.9.101 / 192.168.253.109 | VietinBank VNPT main / FPT backup / Intercom |
| Tunnel57 | 172.16.252.77 | TPBank FPT (peer .78, track 356) |
| Tunnel59 / 63 / 65 | 5.5.5.2 / 5.5.5.6 / 5.5.5.30 | VietinBank FPT (peer .1, track 353, AD 10) / VNPT (peer .5, track 354, AD 1) / Intercom (peer .29, AD 20) |
| Tunnel67 | 10.179.252.25 | Nami voicebot (192.168.25.0/24 → .26) |
| **Gi1/0/6 (routed, shutdown)** | **10.179.255.5/30** | Không description, chưa rõ mục đích. **Không dùng lại** |
- Default route → 10.179.20.123 (FortiGate). Route nội bộ 10.179.70/90/110/120/182/184–188/200 và 172.31.251/253 → FortiGate.
- VLAN: 10 Internet (Gi1/0/11–12, Gi2/0/11–12 → RNET), 20 FW-EXT, 31 VTY (Gi1/0/18), 32 FPTiVoice-HDSS (Gi1/0/19), 70 DMZ, 90 CCX-LAB, 270 PCCE3-VGW, 1009/1010/1018/1082.
- Port trống (VLAN 1, notconnect): Gi1/0/7–10, 14, 20–23; Gi2/0/5–10, 14, 15, 18–23. SFP **1000BASE-BX10-U** đã cắm ở Gi1/1/1 và Gi2/1/1 (chưa link).
- Bất thường: **Gi1/0/15 up nhưng ở VLAN 1, không cấu hình** (inventory ghi "MetroFPT-Lotte-Main"); **route backup TPBank qua VNPT trỏ 172.16.252.82 nhưng không có interface nào trong dải này** → backup có thể không hoạt động; dải 5.5.5.x là IP public của bên khác dùng cho tunnel.

### FortiGate FHN1 (External-Primary / External-Backup, FG-201E)
- HA A-P OK: FG201ETK18901932 (Primary) + FG201ETK18903181, in-sync, heartbeat `ha` + `port10`. **Cluster uptime 2,969 ngày (từ 15/12/2018)**. **`ses_pickup: disable`**.
- `mgmt` 10.179.249.90; `wan1` 10.179.10.110; MGT (VLAN 110) 10.179.110.1; FW-External (VLAN 20) 10.179.20.123; loopback A-CCX 10.179.11.101/.102.
- VLAN BaseBS (VLAN = octet 3): 70 DMZ, 80 Backup, 90 Database, 110 MGT, 120 SYS, 182 A.CCX, 184 DMZ-Ext, 185 UnifyCRM, 186 CN247, 187 IC, 188 LCM → gateway 10.179.X.1.
- **VLAN VietinBank (VLAN = 200 + octet 3, gateway 172.31.X.1)**: 245 PCCE3-UAT, 250 PCCE-Pri, 251 PCCE-Pub, 252 PCCE3-Pri, 253 PCCE3-Pub, 270 PCCE3-VoiceGW, 280 Interact, 281 IBox, 282 PCCE3-APP (172.31.182), 283 NAT, 284 Ext (172.31.184), **285 PCCE3-uCRM (172.31.185)**, 286 CDP, 288 LCM, 289 WFM, **290 PCCE3-DB (172.31.90)**.
