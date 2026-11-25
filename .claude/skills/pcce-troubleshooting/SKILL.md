---
name: pcce-troubleshooting
description: Khoanh vùng sự cố Cisco PCCE/UCCE — cuộc gọi inbound, IVR/CVP, ICM routing, CUCM/CTI, Finesse agent state, báo cáo CUIC/stored procedure. Dùng khi có sự cố cuộc gọi, agent, CTI hoặc số liệu báo cáo sai.
---

# PCCE troubleshooting

## Call flow chuẩn (đối chiếu với note thực tế của từng khách hàng trong `30-Customers/`)
Carrier/SIP trunk → CUBE/Voice GW → CVP Call Server → ICM Router (qua VRU PG) → VXML/IVR → Queue → CUCM (qua CUCM PG/JTAPI) → Agent phone + Finesse (CTI) → UCRM screen pop

## Khoanh vùng theo triệu chứng
| Triệu chứng | Kiểm tra trước |
|---|---|
| Gọi vào bận/rớt ngay | CUBE dial-peer, SIP trunk status CUCM/CVP, `show call active voice brief`, CVP OAMP/Call Server |
| Nghe IVR nhưng không vào queue | ICM routing script (Script Editor monitor), VRU PG status, Call Type báo cáo |
| Kẹt queue dù có agent Ready | Skill group/Precision queue mapping, agent đúng skill, Router log |
| Đổ về agent nhưng không đổ chuông | CUCM PG ↔ CUCM CTIManager, JTAPI user, line device association, CSS/partition |
| Agent không đổi state / Finesse lỗi | Finesse service, CTI server (CG), cert Finesse ↔ CUCM, browser |
| Screen pop UCRM không lên | Finesse gadget/CTI event, ECC variables, kết nối UCRM API |
| Số liệu CUIC sai | Stored procedure, timezone, interval (15/30 phút), HDS replication |

## Log cần xin
- RTMT: CUCM CallManager/CTIManager trace; Router/PG log (`dumplog`); CVP CallServer log; Finesse webservices log.
- Thời điểm cụ thể + số gọi (ANI/DNIS) + agent ID để lọc.

## SQL cho CUIC/HDS (chỉ đọc)
- Luôn giới hạn `DateTime` theo khoảng ngắn; dùng `WITH (NOLOCK)`; chạy ngoài giờ cao điểm.
- Khi sửa stored procedure: viết bản mới tên khác (`_v2`), so sánh kết quả với bản cũ trên cùng khoảng thời gian rồi mới đề xuất thay qua `change-request`.

## Ghi lại
Kiến thức mới → `60-Runbooks/contact-center/`. Sự cố → `incident-rca`.
