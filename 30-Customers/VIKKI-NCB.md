---
type: customer
status: unverified
updated: 2026-11-24
tags: [customer, bank]
---
# VIKKI và NCB

Hai ngân hàng **riêng biệt**, nhưng dữ liệu hiện có chỉ cho thấy chúng **dùng chung nền tảng PCCE1 / Avaya / CTI tại [[FSG01]]**, nên tạm gộp chung một note. Tách thành 2 note khi có thêm dữ liệu riêng cho từng khách.

| Hạng mục | Chi tiết | Nguồn |
|---|---|---|
| Ảnh hưởng sự cố | Sự cố host 11–12/11 ảnh hưởng VIKKI + NCB ([[2026-11-11-FPTDC-host186-LUN-loss]]) | [1N] BRIEF |
| Nền tảng | vCenter FPTDC 10.0.3.50: PCCE1 (10.138.139.2 / .3, ESXi 5.5), 5 CTI VM trên Unity380_LUN1, Avaya G450 10.138.173.x, VoiceGW C3900 10.138.139.51 / .52 | [2N] x01 + x11 |
| Leased line | NCB-FPT VLAN 2625; DongA-FPT VLAN 2622 / DongA-MetroVNPT | [1N] x05 |
| Tên gọi | [SL] VIKKI nhiều khả năng là DongA Bank đổi tên (Vikki Digital Bank). Cần xác nhận | [SL] |

## Cần xác minh
- CTI nào phục vụ khách nào? SIP trunk / dial plan riêng?
- Xác nhận VIKKI = DongA.

## SLA / liên hệ
(bổ sung, không ghi dữ liệu khách hàng nhạy cảm)
