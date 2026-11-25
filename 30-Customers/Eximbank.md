---
type: customer
status: unverified
updated: 2026-11-24
tags: [customer, bank]
---
# Eximbank

## Chủ đề đang làm
- [VAULT] Đánh giá phương án kết nối DC/DR (thiết kế lưu trong `70-Designs/`).

## Hệ thống / kết nối
*(Bổ sung 2026-11-24 từ [[BaseBS-Infra-Master-Overview]]; nguồn x06 = báo cáo VDC 21/11 dựa trên CLI / config)*

| Hạng mục | Chi tiết | Nguồn |
|---|---|---|
| Site | [[VDC-VNPT]] | [2N] x06 |
| Dịch vụ | CCX / uCRM / CRM UAT (cần map tới VM) | [1N] x06 |
| FortiGate VDC | 41 static route, 11 policy, 47 address object mang tên Eximbank | [1N] x06 config 18/11 |
| Đường truyền | RNET-02: subif .2531 **CMC** (172.27.253.102/30, Tunnel197), .3258 **FPT** (172.27.253.122/30, Tunnel217 IPsec over MPLS). Primary là FPT (track 196), CMC làm backup (distance 10) | [1N] x06 CLI |
| Bất thường | Track 196 đã đổi trạng thái 1215 lần trong vòng đời thiết bị (chưa rõ phân bố thời gian) | [1N] x06 |
| Bất thường | Route uCRM UAT 10.128.133.38 **không có trong bảng định tuyến** RNET-02 tại thời điểm snapshot | [1N] x06 |
| SIP | Object "VNPT-SIP-Exim" | [1N] x06 |

Dải mạng nội bộ của ngân hàng không chép vào vault; xem x06 sheet 27 nếu cần.

## SLA / liên hệ
(bổ sung, không ghi dữ liệu khách hàng nhạy cảm)

## Cần xác minh
- Thiết kế DC/DR trong `70-Designs/` có dựa trên MPLS CMC / FPT hiện tại không?
- Nguyên nhân track 196 đổi trạng thái nhiều lần; route .38 bị thiếu.
