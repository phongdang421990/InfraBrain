---
type: site
status: unverified
updated: 2026-11-24
tags: [site, fpt, hcm, basebs]
---
# FSG01 — FPT Tân Thuận DC4 (HCM)

Thuộc [[FDC-FPT]]. Báo cáo tổng: [[BaseBS-Infra-Master-Overview]] §3.2. IP chi tiết: [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục B.

## Thông tin site
| Mục | Giá trị | Nguồn |
|---|---|---|
| Mã site | FSG01 (vCenter gọi "FPTDC"; tài liệu cũ gọi "FDC HCM", "FPT IDC HCM", "SG02") | [2N] x11 StorageLogin + x05 + BG |
| Rack | FDC-TanThuan-DC4-C5, DC4-C6 | [2N] x13 rack + BG_Maintain |
| Môi trường | (1) **FPTDC** legacy: HDSS / PCCE1 / Avaya / CTI, 10.0.3–4.x, 10.138.139/173/180.x. (2) **SG02** Cluster01: 10.138.110.x | [2N] x01 + x11 |
| WAN | Router 877 Internet 192.168.3.1 (PPPoE VNPT theo x05); Router MPLS 2911 **10.127.109.2** (DeviceList ghi .129.2); C8200 ×2, 3845 ×2 | [2N] BG + rack / [1N] x05 |
| Metro khách hàng | ExtSW Po40 MetroFPT (VLAN 2621–2630: Novaland, DongA, KLB, NCB, TPBank, VRB, BVB-FCIbot), Po42 MetroViettel (3127 Daikin), cùng nhiều leased line VNPT | [1N] x05 + x03 |
| Nguồn A/B | Chưa có dữ liệu | — |

## Network
| Thiết bị | Model | IP | Ghi chú | Nhãn |
|---|---|---|---|---|
| FDC.FW01/02 | Palo Alto PA-3020 HA A/P, PAN-OS 7.0, hết subscription | 10.0.4.31 / .32 | Perimeter FDC; có cáp trên BE/DMZ/Ext switch | [2N] x14 + x03 + BG + x21 |
| CLD.FW01/02 (?) | FortiGate 201E (rack C5 U17/U18) | BG ghi serial và IP **trùng với FW02 PVB** (10.199.249.91) | Vai trò và chủ sở hữu chưa rõ (K33) | [SL] |
| ExtSW | C9300-24T stack | 192.168.4.1 | | [2N] |
| BE SW / DMZ SW | C3850 stack | 10.0.4.21 / 10.0.4.22 | | [2N] |
| VoiceGW | C3900 ×2 10.138.139.51 / .52; C8200 10.138.173.56, 10.138.70.11; Avaya G450 ×6 10.138.173.x | | | [2N] |
| SAN SW | Brocade / Connectrix 300 | 10.0.4.100 / .97 | | [2N] |

## VLAN
- Có ID: 2 DMZ, 3 PCCE, 4 Untrust, 8 BE-MGT (10.0.3.252), 10 Backend, 20 DMZ/External-MGT, 26 CLD-WAN-FPT, 36 ASA-PaloAlto, 71 FPT-WAN, 104 Mgmt, 110 DMZ-MGT, 3491 BVB-SIP.
- Gateway FDCHCM-Prod ghi x.x.x.254.
- Nhãn [1N] x03/x05/x18: chưa có running-config.

## ESXi / vCenter
| Host | Model | ESXi | Cluster / vCenter | VM (22/11) |
|---|---|---|---|---|
| 10.138.139.2 / .3 | UCS C240 M4SX | 5.5 | PCCE1 / 10.0.3.50 | 9 + 9, **không có FC** (local disk) |
| 10.0.3.186 (esx21) | UCS C240 M4S | 5.5 | BACKEND | 53 |
| 10.0.3.188 | R650xs | 6.5 | BACKEND | 38 |
| 10.0.3.178 | R650xs | 6.5 | DMZ | 55 |
| 10.138.110.21 / .22 / .23 | R660xs ×2, R650xs | 7.0.3 | SG02 Cluster01 / vcsa.sg02basebs.com 10.138.110.10 | ? |

Nguồn: [2N] x01 (PowerCLI live) + x11. Host .186/.188 đặt ở rack DC4-C6 [1N BG].

## Storage
| Array | IP | Raw | Nhãn |
|---|---|---|---|
| VNXe3200 #1 | 10.0.4.11 | ≈ 32 TB | [2N] |
| VNXe3200 #2 ("VNXe2", lỗi ngày 11/11) | 10.0.4.12 | ≈ 25 TB | [2N] |
| Unity380XT | 10.0.4.10 | ≈ 91 TB; FAST Cache 2 SSD "không nhận" | [2N] / [1N] x14 |

## Khách hàng / dịch vụ
- **[[HD-SAISON]]**: FDCHCM-Prod (Asterisk 173.112/.165, LCM, Nginx, Calabrio); SG02 HDS_Cn247s standby.
- **[[VIKKI-NCB]]**: PCCE1 / Avaya / CTI.
- NTT: uCRM 173.125–127.
- TPBank, KienLongBank, Novaland, VRB, Bảo Việt Bank, Daikin, Amway, InSee, VNTEL, VCCB… qua leased line.
- Backup: 10.138.180.199/.200 (FDC.NAS01), smb.sg02basebs.com.
- Nguồn: [1N] x18 + x08 + x05.

## Sự cố
- [[2026-11-11-FPTDC-host186-LUN-loss]]

## Rủi ro
- ESXi 5.5 trên PCCE1 và .186; PA-3020 EOL / PAN-OS 7.0.
- VNXe3200 năm 2015, linh kiện hiếm.
- 2 vCenter trong cùng 1 site.
- Backup cùng site.
- Xem [[risk-register]] R-004, R-005, R-008, R-010.

## Cần xác minh
- CLD.FW / CLD.RNET là gì (SG02 hay SG03)? FG trong rack C5 có trùng serial với FW02 PVB không? (K13, K33)
- Router 877 dùng PPPoE VNPT hay FPT? Public IP của FSG01 là gì? (chưa có bảng Domain cho FSG01)
- Rack C6 có "VNPT-CORE-SW-01/02" và "LIGHTSMART": đây là thiết bị carrier hay của BaseBS?
- Ai đã đổi uplink vSwitch trên host .186? (K27)
