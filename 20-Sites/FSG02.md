---
type: site
status: unverified
updated: 2026-11-27
tags: [site, fpt, hcm, basebs, smb, lab]
---
# FSG02 — FPT Tân Thuận DC7-C12 (SMB Production + LAB)

Thuộc [[FDC-FPT]]. Báo cáo tổng: [[BaseBS-Infra-Master-Overview]] §3.3. IP chi tiết: [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục C.

## Thông tin site
| Mục | Giá trị | Nguồn |
|---|---|---|
| Mã site | FSG02 / "FSG2"; SMB Connect247 Production + LAB / UAT dùng chung tủ | [2N] x11 + BG + x13 |
| Rack | FPT-TanThuan-DC7-C12 | [2N] |
| WAN / public | WAN1 103.39.93.192/28 (RNET-01), WAN2 42.119.139.16/29 (RNET-02, **dùng chung với [[#SG03]]**), WAN3 43.239.148.240/29 (RNET-03, LAB/UAT). Router public "FSG2.R1" = 210.245.72.172 | [2N] x18 Domain + x06 + FPT Cloud CONF |
| Uplink | WAN-FPT, WAN-FPT-02, WAN-Viettel trên CoreSW | [1N] x05 PortMap |
| IPsec | Tunnel tới RNET-01 VDC ([[VDC-VNPT]]); FPT Cloud S2S (POC) với selector 172.23.90.0/24 và 10.189.70.0/24 | [2N] |

## Network
| Thiết bị | Model | IP | Nhãn |
|---|---|---|---|
| RNET-01/02 (/03) | ISR4331-SEC (+ ISR4331 UC, 2911) | 10.189.10.101 / .102 | [2N] model / [1N] IP; rack chỉ thấy 1 RNET |
| FortiGate | FG-201E, FortiOS 5.6.6 (x21) | DeviceList: 10.189.249.90 (×2); rack / BG: 10.189.110.1, 1 serial | [SL] **có thể chỉ 1 FG vật lý**; .110.1 nhiều khả năng là SVI |
| CoreSW | C9300-48T stack | 10.189.110.20 | [2N]. "Switch 02 10.189.110.10" trong DeviceList là sai, vì .10 là vCenter [SL] |
| VoiceGW | ISR4331-V | 10.189.70.11 / .12 (+ LAB 2911 .13) | [2N] |
| SAN SW | DS-6505B 16G | 10.189.110.5 / .6 | [2N] |
| LAB | Router 1811 / 2811 10.189.13.101; FW-LAB FG-201E 10.189.14.109 / 172.17.203.254; SW-LAB 3560G 172.17.203.203 | | [2N] / [1N] |

## VLAN (x18 Matrix)
10 WAN1 · 12 WAN2 · 70 VoiceGW · 90 DMZ (thực tế có DB) · 110 MGT · 120 SYS · 182 AppSvr · 183 DMZ-Int · 184 DMZ-Ext · 185 UnifyCRM · 186 Cn247 · 187 IC · 188 LCM. Gateway 10.189.x.1. [1N]

## ESXi / vCenter
- Prod: .21 / .22 (R740, 48c / 256 GB), .25 (R650xs). ESXi 6.5, Cluster-01. vCenter 10.189.110.10 (VI SDK, chưa live) [2N host / 1N vCenter].
- .23 / .24 (R640) có trong DeviceList và PortMap, nhưng **không có** trong ServerLogin và BG → có thể đã gỡ [SL].
- BASELAB: 172.17.203.241 / .244 / .248 / .249 / .252, do vCenter LAB 172.23.90.10 quản lý [2N].

## Storage
- Unity380 CKM00200400906, 10.189.110.9, ≈ 96 TB raw. Đĩa slot 1 và 2 đã thay năm 2024 và 05/2026 [2N x14/x17].

## Dịch vụ chính
- `portal.connect247.vn` (103.39.93.199 → proxy 10.189.184.50): IC 187.71, UCRM 185.50 / .56, Connect247 186.50, LCM 188.50, SSO 184.55.
- CUCM 182.31 / .32 / .39; Expressway 182.35 / .55, 183.25 / 184.26; Calabrio 182.37 / .38; K8s CP 184.71–73.
- GitLab 120.23 (backup sang NAS PVB); AD 10.189.120.21; RemoteGW 10.189.90.22.
- Khách: VinHMS, CRM [[VietJet]] 185.56, Connect247 Cloud (đa tenant).
- Nguồn: [2N] x18 + x08.

## SG03
- SG03 "Basebs Cloud" (10.148.x, PDC 10.148.120.20) publish qua loopback trên RNET-02 dùng WAN2 của SMB.
- Vị trí vật lý chưa rõ. Nhiều khả năng dùng chung edge FSG02 [SL].
- **25/11 (live):** VM SG03 chạy trên SG02 Cluster01 ở [[FSG01]] (vcsa.sg02basebs.com). Phần public vẫn đi qua WAN2 của SMB [SL].

## Rủi ro
- ESXi 6.5, FortiOS 5.6.6 EOL.
- FW / RNET có thể không HA.
- LAB và Prod dùng chung tủ và edge.
- Xem [[risk-register]].

## Cần xác minh
- Số FG và RNET thực tế; IP mgmt của từng FG (K15).
- ~~vCenter .110.10 có phải là vCenter không; host .23 / .24 (K14, K16).~~ **Đã giải 25/11:** .110.10 là vCenter; Cluster-01 chỉ có .21 / .22 / .25.
- ~~SG03 đặt ở đâu.~~ Compute ở SG02 Cluster01 ([[FSG01]]); edge public vẫn cần xác minh.

## Live vSphere 2026-11-25
Nguồn: [[2026-11-25-vsphere-health-FSG-FHN]] (vSphere Client UI, read-only).
- **vCenter SMB 10.189.110.10** (vcsa.smbbasebs.com, 6.5.0 b15259038). Datacenter "SMB", Cluster-01.
  - **Chỉ 3 host:** .21 / .22 (R740, 2× Gold 6252, 256 GB, ESXi 6.5.0 b13635690) và .25 (R650xs, 2× Silver 4314, 384 GB, 6.5.0 b19092475).
  - 109 VM (84 bật / 25 tắt).
- **HA ON nhưng Host failure response = Disabled** (host chết thì VM không restart). DRS OFF, EVC Disabled. **RAM 86%** (84 / 86 / 88%), không đạt N+1.
- **NTP hỏng cả 3 host:** .25 ≈ +8 giờ 01 phút; .21 ≈ −4 giờ 13 phút; .22 ≈ −2 giờ 24 phút. → CR nháp [[2026-11-27-ntp-esxi-smb]] (27/11, chờ duyệt; nguồn NTP SMB chưa chốt, [[open-questions]] #43).
- Datastore (VMFS5): BASE_Customer_LUN01 81.5% (Warning từ 21/07/2026), BASE_Backup_LUN01 61%, BASE_Infra_LUN01 55%.
- VM tắt đáng chú ý: BASE_Infra_Wazuh, SELKs, LogSvr; CN247_ExpressC_SUB / ExpressE_SUB; PROD_ReverseProxy01; PROD_UnifyCRM_App03.
- **LAB 172.23.90.10:** chưa rà (cần đăng nhập SSO `vcsa.labbasebs.com`).
