---
type: customer
status: unverified
updated: 2026-11-24
tags: [customer, aviation]
---
# VietJet Air (VJA)

| Hạng mục | Chi tiết | Nguồn |
|---|---|---|
| VDC proxy | VIP FortiGate NAT.187_VJAproxy: 10.169.11.103:443 / 5349 → 10.169.90.60. Public 221.132.28.187:443 qua RNET-01 | [2N] x06 (config 18/11 + CLI NAT) |
| FG VDC | 9 policy, 13 object, route VJA-BSV, VJA.GC_Agent | [1N] x06 |
| SMB | CRM APP VJA 10.189.185.56 (backup NFS 10.189.120.5, 7 ngày) | [1N] x08 |
| DNS | vietjet.connect247.vn có ghi chú "Production, Remove" (DNSrecords 2025) | [1N] NOTES |
| Site | [[VDC-VNPT]], [[FSG02]] | |

## Cần xác minh
- Dịch vụ còn hoạt động không (DNS ghi "Remove" nhưng proxy vẫn có trong config 18/11)?

## SLA / liên hệ
(bổ sung)
