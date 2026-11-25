---
name: incident-rca
description: Quy trình điều tra sự cố production và viết RCA — thu thập log nhiều tầng, chuẩn hóa timestamp, dựng timeline, kiểm định giả thuyết, viết báo cáo RCA và action plan. Dùng khi có sự cố hoặc cần báo cáo sự cố cho quản lý/khách hàng.
---

# Incident & RCA

## 1. Khung sự cố (hỏi chủ vault nếu chưa có)
- Triệu chứng người dùng thấy, thời điểm bắt đầu/kết thúc, phạm vi (khách hàng, dịch vụ, site).
- Thay đổi gần nhất (change, patch, mất điện, đứt link).

## 2. Nguồn log theo tầng — yêu cầu đúng file
| Tầng | Nguồn |
|---|---|
| Storage/Hardware | SAN event log, iLO/iDRAC IML, ESXi `vobd.log` |
| Hypervisor | vCenter Events/Tasks (export), ESXi support bundle: `vmkernel.log`, `hostd.log`, `fdm.log` (HA) |
| VM/OS | Windows System/Application Event Log (Event ID 41, 6008, 1074, 7031/7034), Linux `journalctl` |
| Network | FortiGate event/traffic log, HA log, Cisco `show logging`, interface counters |
| Service | AD/DNS, SQL error log, PostgreSQL log |
| Application | PCCE/CUCM traces (RTMT), CVP log, UCRM log |

File log đặt vào `90-Raw/incidents/<ngay>-<ten>/`.

## 3. Phân tích
1. Chuẩn hóa timestamp → UTC+7 (ESXi log là UTC; ghi rõ độ lệch NTP nếu có).
2. Lọc cửa sổ thời gian [bắt đầu − 30 phút, kết thúc + 15 phút].
3. Dựng timeline hợp nhất: `thời gian | tầng | nguồn | sự kiện`.
4. Giả thuyết: với mỗi cái, liệt kê bằng chứng ủng hộ/phản bác, mức tin cậy.
5. Áp "5 Whys" tới khi chạm nguyên nhân có thể hành động được.

## 4. Báo cáo — theo `Templates/Incident.md`
- Tóm tắt điều hành (≤ 5 dòng, không thuật ngữ thừa)
- Ảnh hưởng: dịch vụ, khách hàng, thời lượng
- Timeline
- Root cause / Contributing factors / Trigger
- Vì sao phát hiện chậm (nếu có)
- Action plan: hạng mục, loại (tạm thời/triệt để), owner, hạn
- Những điều chưa xác minh được

Lưu: `40-Incidents/YYYY-MM-DD-<ten>.md`; link tới note hệ thống, cập nhật risk register.
