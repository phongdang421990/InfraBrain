---
type: customer
status: unverified
updated: 2026-11-24
tags: [customer, bank]
---
# VietBank

Tenant ngân hàng tại [[VDC-VNPT]]. **Không phải [[VietinBank]].** Sheet VM VDC có tiêu đề "VIETBANK-BVbank"; cần xác minh BVBank là khách riêng hay chung hợp đồng.

## Hệ thống / kết nối
| Hạng mục | Chi tiết | Nguồn |
|---|---|---|
| LCM | CUST_LCM_App01 10.169.185.51, App02 .185.53, DB 185.52, 188.62–64 | [2N] x08 + x18 |
| uCRM | Vietbank_UnifyCRM_App01 10.169.187.51, Db01 .187.52 | [2N] x08 |
| CN247 | CUST_Cn247_App01 10.169.184.51, Db01 .184.52 (khả năng cao phục vụ VietBank [SL]) | [1N] x08 |
| FortiGate VDC | 17 route, 9 policy, 18 object (VietBank-Svr / CC / Backend, VietBank_FPT, VietBank_VNPT, VietBank-VPN) | [1N] x06 |
| Đường truyền | Metro FPT + VNPT qua RNET-02 / RNET-NAT; có VPN | [1N] x06 |
| Backup | \\10.169.120.6 hoặc .9 \CN247_Backup\LCM\VietBank, 7 ngày, cùng site | [1N] x08 (K31) |

## Cần xác minh
- Phạm vi hợp đồng, SLA, owner.
- Quan hệ với "BVbank" / "BVB" (Bảo Việt Bank hay Bản Việt?).

## SLA / liên hệ
(bổ sung, không ghi dữ liệu khách hàng nhạy cảm)
