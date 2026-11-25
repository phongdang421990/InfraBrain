---
type: site
status: unverified
updated: 2026-11-24
tags: [site, vnpt, hcm, basebs]
---
# VDC / VNPT — Tân Thuận HCM (rack BX17)

[VAULT] Data Center thuộc phạm vi tiếp nhận hạ tầng của BaseBS.

Site duy nhất có **review live** (CLI / config / vCenter 18–21/11/2026). Báo cáo tổng: [[BaseBS-Infra-Master-Overview]] §2.2, §3.1. IP chi tiết: [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục A. Không thuộc phạm vi Managed Service của FPT. Liên quan: [[FDC-FPT]].

## Thông tin site
| Mục | Giá trị | Nguồn |
|---|---|---|
| Mã | VDC / VSG01 (x05 ghi "Viettel Data Center" là **sai**) | [2N] |
| Rack | VDC-TanThuan-BX17 (42U) | [2N] x13 + x14 |
| Internet | FTTH VNPT 221.132.28.184/29, GW .185. Default route ưu tiên của FG đi qua 10.169.10.100 "FPT Gateway" (thiết bị chưa rõ) | [2N] / [1N] |
| Public | .186 RNET-01 (SSL-VPN :10443 → FG; IPsec hub); .187:443 → VJA proxy; .188 UDP 500/4500, :9443 PRTG | [2N] x06 |
| IPsec hub | RNET-01 tunnel tới FSG2.R1 210.245.72.172, FHN1.R1 103.35.64.45, FHN1.R2, FHN2.R1, FSG1.PA, CLD.R2, HN Office, VinBD | [1N] x06 CLI, khớp x21 |
| MPLS khách hàng | RNET-02: CMC / FPT cho [[Eximbank]], [[VietBank]]; ExtSW Po24 METRO.VNPT, Po26 METRO.FPT (**chỉ còn 1 member**) | [2N] |

## Network
| Thiết bị | Model | IP mgmt | Ghi chú | Nhãn |
|---|---|---|---|---|
| RNET-01 | ISR4431-SEC | 10.169.10.99 (inside); WAN .186 | NAT, IPsec | [2N] |
| RNET-02 | ISR | 10.169.110.8; .30.234 | MPLS, IP SLA 196 (1215 lần đổi trạng thái) | [1N]. DeviceList ghi 10.169.10.101 |
| FortiGate 01 / 02 | FG-201E HA A-P (BASE-IDCVNPT) | 10.169.249.90 / .91 | 315 policy (39 policy service ALL), 154 route, 3 VIP; port WAN của FW02 notconnect | [2N] |
| ExternalSW | 3650-24TS stack | 10.169.20.234 | | [2N] |
| InternalSW | 3650-48TS stack, IOS XE 03.06.06E, uptime ~9 năm | 10.169.110.20 | Trunk 1–4094, NTP off, OutDiscards | [2N] |
| VoiceGW 01–03 | ISR4331-V | 10.169.70.11–13 | | [2N] |
| SAN SW | DS-300B | 10.169.110.5 / .6 | | [2N] |

## VLAN (gateway .1 trên FortiGate)
20 FW-External · 30 RNET-NAT · 70 DMZ / VoiceGW · 90 PUBLIC · 110 MGT · 120 SYS · 181 Ibox · 182 A.CCX · 183 B.CCX · 184 CN247 · 185 LCM · 186 SonyApp · 187 uCRM · 188 Database · 189 WFM · 190 Interaction · 249 MGT-FW. [2N x06]

## ESXi / vCenter
- vCenter vcsa.basebs.com 10.169.110.12, 6.7. 8 host / **107 VM** [2N].
- AppSvr Cluster: .122 (UCS M4S), .123 / .124 (R640), .125 (R660xs). HA on, DRS off, 94 VM. ~~Cert của host .123 hết hạn 31/10/2026~~ → **đã renew 20/11/2026, hiệu lực đến 17/03/2030** [Live 2026-11-24].
- CCX: .21 / .22 (UCS M4S2, ESXi 6.0), .23 / .24 (BE7M-M5, 6.5). Local disk.
- **Live 2026-11-24** ([[2026-11-24-vsphere-health-VDC]]):
  - vCenter 6.7.0 build 24323669; 8 / 8 host Connected; 107 VM.
  - **.123 "Reboot Required"** (uptime 1536 ngày).
  - **Host CCX chạy standalone, không có vSphere HA** (folder A-CCX / B-CCX, không phải cluster). Uptime .21 / .22 / .23 / .24 = 3000 / 3350 / 2706 / 1275 ngày.
  - AppSvr: master HA là .122; RAM .124 = 73%.
  - Alarm 84% của Unity380_Datastore1 **đã bị ack từ trước**, nên không hiện trong All Issues. [Live]
  - **NTP: chỉ .21 / .22 / .23 đồng bộ.** .24, .122, .123: service Stopped. .124, .125: NTP client Disabled. **.125 lệch khoảng +8 giờ**, các host còn lại lệch 6–22 phút. [Live]
  - Build ESXi trong AppSvr: .122 6.0.0 b5050593, .123 6.0.0 b10719132, .124 6.0.0 b13635687, .125 **6.7.0** b20497097. **EVC Disabled**, cluster trộn 3 đời CPU. HA: host isolation và APD/PDL đều Disabled. [Live]
  - VM **B-CUCMPUB 10.169.183.22 (CUCM 12.0 Publisher nhóm B) đang chạy CPU ~100%**. [Live]
  - Network: 18 Standard port group, không có vDS; port group CCX đặt tên trùng lặp (`A-CCX-vlan182` / `A.CCX-VLAN182`). [Live]

## Storage
- Unity350F 10.169.110.9 (≈ 16 TB SSD).
- Unity380 10.169.110.10 (≈ 77 TB): Datastore1 **84%**, Datastore2 58%, Cust_LUN-01, Infra_LUN-01.
- QNAP iSCSI ×2 ở trạng thái Dead.
- Nhãn [2N].

## Khách hàng / dịch vụ
- [[VietBank]] (+ "BVbank"), [[Eximbank]], [[VietJet]] (proxy 10.169.90.60).
- Sony / Hoa Sao, CFC, GHN, Kerry, LaviFood, JioHealth, Savills, Daikin, Vietcredit, Amway, REE (VPN văn phòng).
- Connect247: LB cn247-lb01 10.169.90.56, VIP .58 → CTI 10.169.184.91 / .92.
- PRTG 10.169.120.52; syslog .120.51.
- Backup: 10.169.120.6 hoặc .9 (K31).
- Nguồn: [2N] x06 + x08 + x18.

## Rủi ro
Xem [[risk-register]]: chứng chỉ ESXi hết hạn, ESXi 6.0 / vCenter 6.7, datastore 84%, Po26 suy giảm, 39 policy ALL, NAT 2 tầng, SSL-VPN public.

## Cần xác minh
- Live `get system ha status`; IP mgmt FG02.
- Thiết bị 10.169.10.100 "FPT Gateway" là gì?
- Model RNET-02, và .10.101 có còn dùng không (K10)?
- Export VM 1:1 (ExportList.csv).
- Share backup .6 hay .9 (K31).
