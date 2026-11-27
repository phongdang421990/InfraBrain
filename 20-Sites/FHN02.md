---
type: site
status: unverified
updated: 2026-11-25
tags: [site, fpt, hanoi, basebs, hdss]
---
# FHN02 — FPT Phạm Văn Bạch, Hà Nội (rack L06-M3)

Thuộc [[FDC-FPT]]. Báo cáo tổng: [[BaseBS-Infra-Master-Overview]] §3.5. IP chi tiết: [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục E.

## Thông tin site
| Mục | Giá trị | Nguồn |
|---|---|---|
| Mã | FHN02 / HN02 / "DC-PhamVanBach" | [2N] |
| Rack | FDC-PVB-DC-L06-M3, thiết bị năm 2024 | [2N] x13 + BG + x14 |
| Public | 58.186.204.24/29: .25 dc1-api.basebs.vn, .26 portal.basebs.com.vn, .27 SIP | [2N] x18 + NOTES |
| Metro | HDSS: MetroFPT (main, track 513), MetroCMC (backup, VLAN 2544 192.168.100.42/30), VLAN 2067 SIP HDSS-CMC; SIP trunk FPT / CMC / Digitel | [1N] x05 |

## Network
| Thiết bị | Model | IP | Nhãn |
|---|---|---|---|
| RouterNET.01 / 02 | C8300-SEC | 10.199.10.101 / .102 | [2N] BG + rack |
| VoiceGW 01 / 02 | C8300-V | 10.199.70.11 / .12 | [2N] |
| FortiGate FHN02-FW01 / FW02 | FG-201E (…20905049 Primary / …20905355) | `mgmt` **10.199.249.91** (cả cụm; trước ghi .90/.91); in-band MGT **10.199.110.1**; FW-External 10.199.20.123 | [Live CLI 24/11]. HA OK → **K33 đã giải**: FW02 nằm ở PVB |
| ExtSW | C9300-24T-E stack | 10.199.20.234 | [2N] BG + x05 |
| IntSW | C9200-48T-S stack | 10.199.110.20 | [2N] |
| SAN SW | D6500 / G620 | 10.199.110.5 / .6 | [2N] |

## ESXi / vCenter / storage
- AppSvrs: .21 / .22 R650xs, .23 R660xs. ESXi 7.0.3. vCenter 10.199.110.10 [2N host / 1N vCenter].
- **Live 2026-11-24** ([[2026-11-24-ket-noi-FHN01-FHN02-app-db]]):
  - vcsa.hn02basebs.com 7.0.3 b22837322; 3 host, 116 VM.
  - HA ON (admission control 35% CPU / 33% RAM), DRS ON ở chế độ **Manual**, EVC Disabled.
  - RAM 858 / 1,120 GB (77%): .21 71%, **.22 84%**, .23 67%. **Không đạt N+1 về RAM.** Uptime .21 / .22 981 ngày, .23 463 ngày.
  - Datastore: **UnityHN02_LUN01 91% (còn 3.36 / 37.81 TB), có alarm**; UnityHN02_LUN02 44% (còn 5.55 / 10 TB). [Live]
- Unity380 CRK00240415710, 10.199.110.9, ≈ 80 TB raw [2N].
  - **Live 2026-11-24:** pool `BASEBS_Prod` **50.8 TB usable, Free 2.6 TB, Subscription 94.9%**. 2 datastore VMFS (LUN01 38,720 GB, LUN02 10,240 GB) đã cấp phát khoảng 100%. Khoảng 617 IOPS, SP 8.9%. Data reduction 1:1.
- uCRM của BaseBS trên PVB: 17 VM (`PROD_UCRM_*`, `PROD_UCRMv4_*`, `PROD_uCRMv5_DB_10.199.90.65`; folder UCRMv5 / UCRMv4-VMs / UCRM-VMs). **Không phải VTB.** [Live]
- NAS backup `nassvr.hn02basebs.com` 10.199.80.200 / 10.199.110.200 (VM FreeBSD) [1N].

## Khách hàng / dịch vụ
- **[[HD-SAISON]]** (HDSS-PROD, khoảng 48 IP):
  - HDS_Cn247s App / DB / Interact / Jtapi / Voiceportal (186.x).
  - Kamailio 184.53 / .54 / .71; Proxy 184.51 / .52.
  - CUCM Pub 182.20 / Sub 182.21–.22; Calabrio 182.51–57 + DB 90.21 / .22; Recording 182.61–74.
- **UCRM Cloud / BaseApp** (khoảng 79 IP): UCRM v3 / v4 / v5, ApiGw, Proxy, Ibox, LCM, IC, WFM, Interact (180.x), SQL Witness, Checkmk, Centrallog, Percona.
- AD hn02basebs.com 10.199.120.20; RemoteGW DB 10.199.90.25.
- Nhận backup GitLab của SMB (bản off-site duy nhất thấy được).
- [VAULT] [[VietinBank]] có kiến trúc UCRM giữa PVB và Duy Tân (đang thiết kế).

## Rủi ro
- FortiOS 5.6.6 (x21).
- 3 host cho rất nhiều dịch vụ: cần kiểm tra N+1.
- Wazuh / NAS chạy dạng VM.

## Cần xác minh
- Có liên kết trực tiếp PVB ↔ Duy Tân không, hay chỉ có IPsec qua VDC (K20)? **24/11:** không có kênh DC↔DC của BaseBS; nhưng FHN1 (.51) và FHN2 (.50) cùng nằm trong segment Metro FPT của HDSS 192.168.100.48/29 (kênh của khách hàng, không dùng cho BaseBS).
- ~~FW02 có thực sự nằm ở PVB không (K33)?~~ **Đã xác nhận 24/11**: cụm FHN02-HA đủ 2 máy, in-sync.
- Route 10.69.68.0/24 "VSG.VPN" (pool VPN admin?). **24/11:** có trên ExtSW → 10.199.20.123; máy chủ vault đi VPN với IP 10.69.68.8.

## Network live (CLI chủ vault chạy, 2026-11-24)
### FHN2.ExtSW (2× C9300L-24UXG stack)
| Interface | IP | Vai trò |
|---|---|---|
| Vlan20 | 10.199.20.234/24 | Quản trị + next-hop tới FortiGate 10.199.20.123 |
| Vlan2544 | 192.168.100.42/30 | HDSS Metro CMC backup (peer .41, AD 10) |
| Vlan2067 | — | HDSS SIP CMC (L2) |
| **Gi1/0/20 (routed)** | **192.168.100.50/29** | HDSS Metro FPT main (peer .49, track 513). Inventory không ghi |
| Gi0/0 | 10.29.30.252 (down) | Cấu hình cũ |
- **Không có default route.** Route: HDSS 10.8/10.9/10.10/10.11/10.80/10.101 → .49 (main) / .41 (backup); `10.199.0.0/16 Internal-Apps`, `10.69.68.0/24 VSG.VPN`, `10.169.120.0/24 VSG.Sys` → 10.199.20.123.
- VLAN: 10 FW-RNET (Gi1/0/3–4, Gi2/0/3–4), 20 FW-External, 21 FPT-WAN (Gi1/0/15–16), 22 VNPT-WAN (Gi2/0/14–15), 31 FPT-iVoice, 32 VNPT-iVoice, 33 Digitel-iVoice, 34 FPT-HDSS, 70 VoiceGW, 2067, 2544.
- Port trống: Gi1/0/6–12, 19, 21–24; Gi2/0/6–12, 16, 19, 21–24. SFP **BX10-U** ở Gi1/1/1, Gi2/1/1 (chưa link).
- Bất thường: **Gi2/0/15 (VNPT-WAN), Gi1/0/16 (FPT-WAN), Gi1/0/17 / Gi2/0/17 (SIP)** đang notconnect → xác nhận đường WAN/SIP nào đã bỏ.

### FortiGate FHN02-FW01 / FW02
- HA A-P `FHN02-HA` OK: FG201ETK20905049 (Primary) + FG201ETK20905355, in-sync; cluster uptime 902 ngày; **`ses_pickup: disable`**.
- `wan1` 10.199.10.110; FW-External (VLAN 20, External) 10.199.20.123; VoiceGW (VLAN 70) 10.199.70.1; loopback DMZ-Ext 10.199.11.101–.103.
- VLAN nội bộ (Internal, VLAN = octet 3, gateway 10.199.X.1): 80 Backup, 90 Database, 110 MGT, 120 System, 180 Interaction, 181 Ibox, 182 Application, 183 DMZ-Int, 184 DMZ-Ext, 185 uCRM, 186 Cn247, 187 IC, 188 LCM, 189 WFM.
- **Chưa có dải 172.31.x nào ở PVB.** Subnet VTB mới đề xuất: **VLAN 291 – 172.31.91.0/24**, gateway 172.31.91.1 (theo quy ước VLAN VTB = 200 + octet 3 ở Duy Tân).

### Kênh transit Metro Duy Tân ↔ PVB (đề xuất, chưa triển khai)
- **10.179.254.0/30** (dải mới, đã kiểm tra chưa dùng trên 2 ExtSW và 2 FortiGate ngày 24/11): FHN1.ExtSW Gi1/0/20 **.1** ↔ FHN2.ExtSW Gi1/0/21 **.2** (routed port; hoặc Gi1/1/1 nếu FPT giao quang BX, đầu FPT cần BX10-D). Không dùng lại 10.179.255.4/30.
- Chi tiết route + policy: Sheet https://claude.ai/artifact/EqgKL7TgkeRU8bFXoXbkbW (tab Quy hoạch IP, Luồng mạng & FW). Triển khai qua `change-request`.

## vSphere live bổ sung (2026-11-25)
Nguồn: [[2026-11-25-vsphere-health-FSG-FHN]].
- ESXi: .21 / .22 7.0.3 b23307199 (R650xs, Gold 5320), .23 7.0.3 b24411414 (R660xs, Gold 6442Y). vSphere 7 đã hết general support từ 02/10/2025.
- NTP OK cả 3 host; có VM NTP riêng `BASE_Infra_NTP_10.199.120.21`. Cert hạn 13/03/2029 (.21 / .22), 17/08/2030 (.23).
- Alarm duy nhất: UnityHN02_LUN01 Critical **từ 19/11/2025** (chưa ack).
- VM 116 (103 bật / 13 tắt). **Cụm PROD_IC tắt toàn bộ** (App01 / 02, DB01–04, Elk, khoảng 2.5 TB) → ứng viên giải phóng LUN01 (xem [[open-questions]] #28).
