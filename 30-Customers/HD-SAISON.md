---
type: customer
status: unverified
updated: 2026-11-24
tags: [customer, finance]
---
# HD SAISON (HDSS)

## Hệ thống / kết nối
| Hạng mục | Chi tiết | Nguồn |
|---|---|---|
| Site chính | [[FHN02]] (PVB): HDSS-PROD, gồm HDS_Cn247s (App / DB / Interact / Jtapi / Voiceportal 10.199.186.x), Kamailio 184.53 / .54 / .71, Proxy 184.51 / .52, CUCM Pub 182.20 / Sub 182.21–.22, Calabrio 182.51–57 + DB 90.21 / .22, Recording 182.61–74 | [1N] x18 FDCHN02-HDSS-PROD |
| Site thứ 2 | [[FSG01]]: SG02 HDS_Cn247s (App 10.138.186.51 / .52, DB 90.51 / .52, Interact, Redis); FDCHCM-Prod (Asterisk 10.138.173.112 / .165, LCM HDSS, Nginx, Calabrio DB); AD 10.0.3.20 / .47 | [1N] x18 SG02 / FDCHCM-Prod |
| Active / standby | [SL] HDS_Cn247s active ở PVB, standby ở SG02 (cùng mô hình đặt tên); sheet SG02 có tên "HCM_HDSS_PROD_C247Stand" | [SL] |
| Đường truyền | PVB: MetroFPT (main, track 513), MetroCMC (backup, VLAN 2544), SIP HDSS-CMC VLAN 2067, SIP Digitel / FPT. Duy Tân: VLAN 1082 HDSS-MetroFPT, FPT iVoice-HDSS. FSG01: HDSS-MetroFPT / VNPT | [1N] x05 |
| Public | 58.186.204.25 dc1-api.basebs.vn, .26 portal.basebs.com.vn, .27 SIP (PVB) — [SL] có thể phục vụ HDSS | [2N] mapping / [SL] gán khách |
| Backup | NAS PVB `nassvr.hn02basebs.com` (HDS-C247st); SG02: `smb.sg02basebs.com`; HCM: 10.138.180.199 | [1N] x08 |

## Cần xác minh
- Site nào đang active? RPO / RTO? Replication DB giữa PVB và SG02 chạy thế nào?
- Public IP PVB có thuộc HDSS không?

## SLA / liên hệ
(bổ sung, không ghi dữ liệu khách hàng nhạy cảm)
