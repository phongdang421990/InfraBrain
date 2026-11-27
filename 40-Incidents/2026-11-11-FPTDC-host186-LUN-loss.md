---
type: incident
status: investigating
severity: P1
start: 2026-11-11 17:16
end: 2026-11-12 00:12 (5 CTI bật lại; thời điểm dịch vụ phục hồi hoàn toàn chưa xác nhận)
customer: [VIKKI, NCB]
systems: [ESXi 10.0.3.186, ESXi 10.0.3.188, ESXi 10.0.3.178, VNXe3200 10.0.4.12, Unity380XT 10.0.4.10, vCenter 10.0.3.50]
updated: 2026-11-25
tags: [incident, vmware, storage, fptdc]
---
# 2026-11-11 — FPTDC: mất truy cập LUN, host 10.0.3.186 Not Responding, 5 CTI VM tắt

Site: [[FSG01]]. Khách hàng: [[VIKKI-NCB]]. Nguồn chính: **x01** `BaseBS_FDC_Incident_Executive_Report_20261122.xlsx` (PowerCLI, vobd / hostd log, vCenter EventEx, support bundle 22/11). Báo cáo tổng: [[BaseBS-Infra-Master-Overview]] §1.2, §2.3.

## Tóm tắt điều hành
- Lúc 17:16 ngày 11/11, 3 host ESXi của vCenter FPTDC cùng mất truy cập các LUN trên VNXe3200 #2 ("VNXe2"). Datastore Unity380_LUN1, nơi chứa 5 CTI VM, bị heartbeat timeout lặp lại.
- Host **10.0.3.186** (esx21, UCS C240 M4S, ESXi 5.5, 53 VM) Not Responding lúc 17:52, sau đó reboot lúc 20:43 không rõ nguyên nhân, và kết nối lại vCenter lúc 20:46.
- 5 CTI VM được bật lại lúc 00:12 ngày 12/11.
- **Root cause chưa chốt**: nghi array VNXe2 hoặc FC fabric. Thiếu log vmkernel trước reboot; SEL đã đầy từ 2021.

## Ảnh hưởng
- Dịch vụ: CTI (5 VM / 7 VMDK trên Unity380_LUN1). Thêm VM 05_web3 (crash vmx) và BASE_BE07_FREENAS bị lỗi swap.
- Khách hàng: VIKKI, NCB [1N BRIEF].
- Thời lượng: 17:52–20:46 là thời gian **mất quản trị**. Đây chưa phải thời lượng outage của ứng dụng; thời lượng thực tế chưa xác nhận.

## Timeline (UTC+7)
| Thời gian | Tầng | Nguồn | Sự kiện |
|---|---|---|---|
| 11/11 17:16:05–07 | Storage | vobd .186; vCenter EventEx .188 / .178 | 3 host cùng mất access VNXe2_BE_03–07 |
| 17:16:44 | FC | vobd L3586–3597 | Nhiều path vmhba2 / vmhba3 Dead |
| 17:19–17:20 | Storage | vobd | Unity380_LUN_Backup, rồi **Unity380_LUN1 (CTI)** heartbeat timeout |
| 17:20–17:22 | Mgmt | hostd | multipathStateInfo 234 s; storageDeviceInfo 120 s |
| 17:23:57 | FC | vobd | 2 path C0:T0:L0 Dead thuộc **VNXe2_BE_03** (không phải Unity380) |
| 17:27–17:29 | VM | vobd | 05_web3 và BASE_BE07_FREENAS lỗi fault-in swap |
| 17:44, 18:20 | HW | vobd | MCE CPU bank 10 / 14 |
| 17:52:38 | Mgmt | vCenter | .186 HostConnectionLost; 5 CTI VmDisconnected |
| 19:08 | VM | vobd | 05_web3 crash vmx (zdump) |
| 19:29–19:31 | Storage | vobd | Unity380_LUN1 timeout, rồi recovered lần cuối |
| 20:43:52 | Boot | PowerCLI BootTime | .186 boot; nguyên nhân / người thực hiện chưa rõ |
| 20:46 | Mgmt | vCenter | HostConnected; 5 CTI ở trạng thái PoweredOff |
| 12/11 00:12 | Recovery | vCenter | 5 CTI được bật |
| 12/11 01:53–03:05 | Network | vCenter | vmnic3 / 4 / 6 / 7 của .186 up/down nhiều lần |
| 12/11 ~09:51 | Config | vCenter | Reconfigure vNIC CTI_App01 / 02 (bởi tài khoản quản trị) |

## Phân tích
### Giả thuyết
| # | Giả thuyết | Ủng hộ | Phản bác | Tin cậy |
|---|---|---|---|---|
| H1 | Lỗi ở array VNXe2 (SP / port) | Nhiều host cùng mất LUN VNXe2 cùng lúc | Unity380 cũng bị timeout | Trung bình |
| H2 | Lỗi ở FC fabric (Brocade 10.0.4.100 / .97) | Ảnh hưởng cả 2 array trên .186 | Chưa có port map, CRC, RSCN | Trung bình |
| H3 | Reset nguồn do thao tác thủ công / PDU | Có boot nhưng vCenter không có event reboot | Không có CIMC audit | Thấp |
| H4 | Lỗi CPU / RAM (MCE) | MCE bank 10 / 14 | MCE đã từng xuất hiện ở các ngày khác | Thấp–TB |

### Kết luận
- Root cause: **chưa chốt**.
- Contributing factors:
  - ESXi 5.5 (hostd chậm khi storage bất ổn).
  - VNXe3200 2015 đã EOL.
  - SEL overflow; không có remote syslog trước reboot.
  - Có 9 alarm tồn đọng từ 2018–2025.
- Đính chính: bản tổng hợp 13/11 gán sự cố cho **PCCE1 10.138.139.2 / .3 "52 VM"**. Đây là sai; host bị ảnh hưởng là **.186** (53 VM).

## Action plan (trích x01 sheet 05)
| Hạng mục | Loại | Owner | Hạn | Trạng thái |
|---|---|---|---|---|
| A01 Bảo toàn support bundle / CSV, tạo hash | RCA P0 | | | |
| A02 Lấy log FC SAN switch 11/11 17:00–20:50 | RCA P0 | | | |
| A03 Lấy log audit / controller / FC port của VNXe2 | RCA P0 | | | |
| A04 Lấy event / latency theo LUN của Unity380 | RCA P0 | | | |
| A05 Kiểm tra Syslog.global.logHost | RCA P1 | | | |
| A06 Đối chiếu DC ticket / PDU / CIMC cho lần reboot 20:43 | RCA P1 | | | |
| A07 MCE bank 10 / 14 | RCA P1 | | | |
| A08 HA / admission control / anti-affinity | RCA P1 | | | |
| A09–A10 Kiểm tra ứng dụng 5 CTI, 05_web3, FREENAS | Service P1 | | | |
| A11–A16 Rà alarm (VNXe2_BE_04 / 07 Critical; uplink .2; cert vCenter …) | Alarm | | | |
| A17 Rà tài khoản host và failed login 12/11 | Security P1 | | | |

Mọi thao tác thay đổi (clear SEL, đổi multipath, reboot) phải đi qua `change-request`.

## Chưa xác minh được
- Thời lượng outage CTI thực tế; ai / cái gì đã reboot .186.
- Map zoning WWPN (.186: vmhba2 …BE:65, vmhba3 …BE:66) tới port của array.
- Vì sao uplink vSwitch khác với inventory (vmnic7 / 3 thay vì vmnic6 / 4).

## Bằng chứng
- x01 (sheet 01 Timeline, 02 RCA, 05 Action Plan, 07 Asset Map); nguồn gốc là vobd.log, hostd.6.gz, vmksummary.log, FDC_ESXi_186_11Nov.csv, FDC_CTI_Events_11-13Nov.csv.
- Nên chép support bundle vào `90-Raw/incidents/2026-11-11-FPTDC/`, không commit.

## Bổ sung 2026-11-25 (live vSphere, [[2026-11-25-vsphere-health-FSG-FHN]])
- **Phạm vi rộng hơn hồ sơ: host SG02 10.138.110.22 (vCenter khác, cùng site FSG01) cũng khởi động lại trong đêm.**
  - Uptime 13 ngày; Hardware Health ghi lần cập nhật sensor cuối 12/11 03:04:53.
  - Event "system clock stepped … lost synchronization" lúc 12:42:52 ngày 12/11 → trước đó giờ của host đã sai.
  - VM `Infra_VCSA_10.138.110.10` (chính vCenter SG02) chạy trên .22, có event "Virtual machine is starting" lúc **09:51:34 ngày 12/11** (theo đồng hồ host). Cluster SG02 tắt HA.
  - [SL] vCenter SG02 và các VM trên .22 nằm tắt từ khoảng 03:00 tới khoảng 09:51.
  - Thời điểm khoảng 03:04 trùng cuối cửa sổ vmnic của .186 lên xuống (01:53–03:05) → nghi có thao tác vật lý / mạng trong DC4 đêm đó.
- **Đồng hồ host lệch:** .178 ≈ +7 phút, .188 ≈ −8 phút (NTP tắt; số đo ngày 25/11). Khi dùng log cục bộ (`vobd`, `vmkernel`, `hostd`) của 2 host này phải hiệu chỉnh. .186 chạy NTP (lệch ≈ 20 s). Timestamp event của vCenter không bị ảnh hưởng.
- **Hiện trạng 25/11:**
  - .186 vẫn ESXi 5.5.0 b2068190, uptime 13 ngày.
  - Cả 3 cluster FPTDC tắt HA / DRS.
  - VNXe2_BE_07 88%, BE_04 85%.
  - Unity_DAE01_Backup02 được mount ở cả FPTDC và SG02.
- Việc cần thêm:
  - Thu log SG02 .22 quanh 12/11 00:00–10:00.
  - Hỏi DC FPT về thao tác trong rack DC4 đêm 12/11.
  - Ghi thời gian downtime của vCenter SG02 và các dịch vụ SG02 / SG03 vào phần Ảnh hưởng.
