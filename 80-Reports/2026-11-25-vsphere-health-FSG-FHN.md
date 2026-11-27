---
type: report
status: final
updated: 2026-11-25
tags: [report, health-check, vsphere, fsg01, fsg02, fhn01, fhn02, basebs]
---
# Health check vSphere các site còn lại (FSG01, FSG02, FHN01, FHN02): 2026-11-25

- **Nguồn:** vSphere Client UI **live**, đọc trong khoảng 14:48–15:50 ngày 2026-11-25 (UTC+7) qua Claude in Chrome, dùng các phiên đăng nhập sẵn có trên Chrome của máy công ty (SG02 và SMB: tài khoản `tinn`; FPTDC: `dangtp@VCENTERBASE`; FHN01, FHN02: phiên có sẵn). Claude không nhập mật khẩu.
- **Chỉ đọc:** chỉ bấm cây inventory, tab, menu điều hướng, nút mở rộng và bộ lọc hiển thị (số dòng mỗi trang). JavaScript chỉ dùng để đọc text và cuộn lưới. **Không** bấm Acknowledge, Reset, Edit, Power, Console, Renew.
  - Lưu ý: khi mở trang *Hardware Health* ở SG02, vSphere Client **tự chạy** tác vụ "Refresh hardware IPMI System Event Log" trên 3 host (chỉ đọc SEL, ghi dưới phiên `SG02BASEBS\tinn`, 14:52). Mở trang EVC tự tạo tác vụ "Retrieve EVC". Không có thay đổi cấu hình nào.
- **Phạm vi:** 5 vCenter, **23 host, 689 VM**. **Chưa rà LAB 172.23.90.10**: trang chuyển sang SSO `vcsa.labbasebs.com`, chưa có phiên đăng nhập.
- **Cách đo lệch giờ:** so trường "Date & Time" của host với đồng hồ trình duyệt. Các host có NTP Running đều cho giá trị thô −12 đến −15 s (máy trạm nhanh khoảng 13 s), nên lấy đó làm mốc 0. Sai số khoảng ±10 s.
- Liên quan: [[FSG01]] · [[FSG02]] · [[FHN01]] · [[FHN02]] · [[2026-11-24-vsphere-health-VDC]] · [[2026-11-11-FPTDC-host186-LUN-loss]] · [[risk-register]] · [[open-questions]] · [[VietinBank]] · [[HD-SAISON]]

## 1. Tóm tắt cho quản lý
1. **Không host nào mất kết nối**, chứng chỉ host đều còn hạn (2028–2031). Nhưng **đồng hồ ESXi lệch nặng ở 9/23 host**, từ 7 phút tới 8 giờ, trong đó có 2 host PCCE3 của [[VietinBank]] (chậm 19 và 25 phút) và cả 3 host SMB/Connect247.
2. **4/5 vCenter không có vSphere HA hoạt động thực sự:** SG02, FPTDC, FHN01 tắt HA; SMB bật HA nhưng *Host failure response = Disabled* và RAM đã dùng 86%. Host chết là VM trên host đó nằm im cho tới khi có người bật tay. Việc này **đã xảy ra đêm 11–12/11**: host SG02 .22 khởi động lại, vCenter SG02 (chạy trên .22) chỉ được bật lại khoảng 09:51 sáng 12/11.
3. **Nền tảng hết hỗ trợ:** 3/5 vCenter là 6.5 (bản FPTDC từ 2017), 17/23 host chạy ESXi 5.5/6.5, 6 host còn lại chạy 7.0.3 (vSphere 7.x hết general support từ 02/10/2025, Broadcom KB 415405). Nhiều server Dell đời mới (R650xs/R660xs) đang chạy ESXi 6.5, nhiều khả năng ngoài HCL.

| Mức | Phát hiện chính |
|---|---|
| 🔴 | 9/23 host lệch giờ ≥ 7 phút (tối đa khoảng 8 giờ), gồm PCCE3 VietinBank; SG02, FPTDC, FHN01 tắt HA; SMB bật HA nhưng tắt restart, RAM 86%, không đạt N+1; FPTDC cụm DMZ chỉ 1 host (55 VM); ESXi 5.5 (2014) và vCenter 6.5 (2017) ở FPTDC; sự cố 11/11 lan sang SG02 nhưng chưa có trong RCA |
| 🟠 | Datastore ≥ 85% (FHN02 LUN01 91% treo alarm 1 năm, FHN01 Cust_SAN.BK 91%, FPTDC VNXe2_BE_07 88% / BE_04 85%); 4 cluster trộn đời CPU mà EVC tắt; FPTDC .139.2 mất uplink redundancy từ 26/08 (alarm đã bị ack); server đời mới chạy ESXi 6.5 |
| 🟡 | VM tắt chiếm khoảng 23.7 TB; datastore dùng chung giữa 2 vCenter và template đăng ký 2 nơi; VM giám sát bảo mật SMB đang tắt; license vCenter FPTDC chưa xác minh; Skyline Health SG02 báo lỗi từ 03/2026; IPMI SEL không đọc được ở SG02 .21 / .23 |
| 🟢 | 23/23 host Connected; cert host hạn 2028–2031; SG02, FHN02 và 5/6 host A-App FHN01 đồng bộ NTP tốt |

## 2. Tổng hợp chéo các site

### 2.1 vCenter và nền tảng
| vCenter | Site | Bản | Host | VM (bật / tắt) | RAM dùng | Storage dùng | Cluster: HA / DRS / EVC |
|---|---|---|---|---|---|---|---|
| vcsa.sg02basebs.com 10.138.110.10 | [[FSG01]] (SG02 + SG03) | 7.0.3 b22837322 | 3 | 99 (98 / 1) | 743 GB / 1.12 TB (65%) | 21.6 / 43.1 TB (50%) | Cluster01: **OFF / OFF / Disabled** |
| 10.0.3.50 (SSO `VCenterBASE`) | [[FSG01]] (FPTDC) | **6.5.0 b5973321** | 5 | 164 (111 / 53) | 767 GB / 1.37 TB (55%) | 61.4 / 98.1 TB (63%) | BACKEND, DMZ, PCCE1: **OFF / OFF** |
| vcsa.smbbasebs.com 10.189.110.10 | [[FSG02]] (SMB) | 6.5.0 b15259038 | 3 | 109 (84 / 25) | **772 GB / 894 GB (86%)** | 19.4 / 28.3 TB (68%) | Cluster-01: ON nhưng **restart Disabled** / OFF / Disabled |
| vcsa.ccxbasebs.com 10.179.110.10 | [[FHN01]] | 6.5.0 b24045034 | 9 | 201 (192 / 9) | 1.69 / 2.58 TB (66%, 24/11) | 70.0 / 91.2 TB (77%, 24/11) | A-App: **OFF / OFF / Disabled** |
| vcsa.hn02basebs.com 10.199.110.10 | [[FHN02]] | 7.0.3 b22837322 | 3 | 116 (103 / 13) | 858 GB / 1.12 TB (77%, 24/11) | — | AppSvrs: ON (AC 35% / 33%) / Manual / Disabled |
| 172.23.90.10 (LAB) | [[FSG02]] | chưa rà | | | | | |

### 2.2 🔴 NTP và lệch giờ ESXi (mở rộng [[risk-register]] R-014)
| vCenter | Host | NTP client / service | NTP server | Lệch so với host chuẩn |
|---|---|---|---|---|
| SMB | 10.189.110.25 (R650xs) | Disabled / Stopped | (trống) | **≈ +8 giờ 01 phút** |
| SMB | 10.189.110.21 (R740) | Disabled / Running | 10.189.120.20 | **≈ −4 giờ 13 phút** |
| SMB | 10.189.110.22 (R740) | Enabled / **Stopped** | 10.189.120.20 | **≈ −2 giờ 24 phút** |
| FHN01 | 10.179.110.22 (R640, A-App) | Enabled / **Stopped** | **10.189.120.20** (NTP của SMB, sai site) | **≈ +7 giờ 58 phút** |
| FHN01 | 10.179.110.53 (A-CCX) | Disabled / Stopped | (trống) | **≈ −1 giờ 00 phút** |
| FHN01 | 10.179.110.45 (**PCCE3-A, VietinBank**) | Enabled / **Stopped** | 10.179.120.20 | **≈ −25 phút** |
| FHN01 | 10.179.110.47 (**PCCE3-B, VietinBank**) | Enabled / **Stopped** | 10.179.120.20 | **≈ −19 phút** |
| FPTDC | 10.0.3.188 (BACKEND) | Disabled / Stopped | (trống) | **≈ −8 phút** |
| FPTDC | 10.0.3.178 (DMZ) | Disabled / Stopped | (trống) | **≈ +7 phút** |
| FPTDC | 10.0.3.186 (BACKEND) | Enabled / Running | 10.0.3.47, 10.0.3.39 | ≈ −20 s (NTP chạy nhưng vẫn lệch, cần `ntpq -p`) |
| Tất cả còn lại | SG02 ×3, FHN02 ×3, FHN01 .21/.23/.24/.25/.26, FPTDC .139.2/.139.3 | Running | site tương ứng | ≈ 0 (trong sai số) |

Nhận xét:
- Gộp với VDC ngày 24/11 (5/8 host lỗi NTP, .125 lệch +7 giờ 57 phút): **14/31 host ESXi của BaseBS đang lệch giờ hoặc không chạy NTP.**
- Có một **mẫu lặp lại**: 3 host lệch khoảng +8 giờ (SMB .25, FHN01 .22, VDC .125). [SL] Nhiều khả năng giờ hệ thống bị đặt theo giờ địa phương khi cài, rồi không bao giờ bật NTP.
- Hệ quả:
  - VMware Tools đồng bộ giờ một lần cho guest khi vMotion, snapshot (backup) hoặc resume. Guest trên host lệch có thể **nhảy giờ hàng giờ**. Rủi ro cao với CUCM/UCCX/PCCE, Expressway (TLS/SIP), Kerberos/AD, CDR và ghi âm.
  - Log và timeline RCA sai giờ. Ví dụ log cục bộ của FPTDC .178/.188 dùng trong RCA sự cố 11/11 lệch ±7–8 phút.
  - PCCE3 VietinBank: hai phía A/B lệch nhau khoảng 6 phút và cùng chậm 19–25 phút so với giờ chuẩn.

### 2.3 🔴 Khả năng chịu lỗi host (HA, N+1)
| Cluster | HA | Host failure response | DRS | EVC | N+1 RAM (dùng / còn lại khi mất host lớn nhất) | Ghi chú |
|---|---|---|---|---|---|---|
| SG02 Cluster01 | **OFF** | — | OFF | Disabled (Gold 6442Y + Gold 5320) | 743 / 765 GB = **97%** | Chứa chính vCenter SG02, toàn bộ VM SG03, HDSS standby |
| FPTDC BACKEND (.186, .188) | **OFF** | — | OFF | — | 338 / 383 GB = 88% | .186 ESXi 5.5 |
| FPTDC DMZ (.178) | **OFF** | — | OFF | — | **1 host duy nhất, 55 VM** | SPOF hoàn toàn |
| FPTDC PCCE1 (.139.2, .139.3) | **OFF** | — | OFF | — | local disk, không failover được | Theo thiết kế phía A/B của PCCE |
| SMB Cluster-01 | ON (master .22) | **Disabled** (cả isolation, APD, PDL, VM monitoring) | OFF | Disabled (Gold 6252 + Silver 4314) | 772 / 511 GB = **151%**: thiếu khoảng 261 GB | AC giữ lại 41% CPU / 43% RAM nhưng không có tác dụng vì không restart |
| FHN01 A-App (6 host) | **OFF** | — | OFF | Disabled (3 đời CPU) | khoảng 85–90% (ước tính từ số 24/11: 1.48 / 2.12 TB) | R-017 |
| FHN02 AppSvrs | ON | Restart | Manual | Disabled (Gold 5320 + Gold 6442Y) | không đạt (R-020) | |
| VDC AppSvr (24/11) | ON | Restart | OFF | Disabled | đạt (AC 37% / 27%) | R-015 |

### 2.4 🔴 Phiên bản EOL và tương thích phần cứng
| Bản | Ở đâu | Ghi chú |
|---|---|---|
| ESXi **5.5.0 b1746018 / b2068190** (2014) | FPTDC .139.2, .139.3 (PCCE1), .186 (BACKEND) | .139.2 chạy liên tục **3,668 ngày (~10 năm)**, .139.3 3,190 ngày. ESXi 5.5 không còn quản lý cert |
| ESXi 6.5 (b8294253 … b20502893) | FPTDC .178 / .188, SMB ×3, FHN01 ×9 | **FHN01 dùng 4 build 6.5 khác nhau** |
| ESXi 7.0.3 b23307199 / b24411414 | SG02 ×3, FHN02 ×3 | 7.x hết general support 02/10/2025 |
| vCenter 6.5.0 b5973321 (2017) | FPTDC | Bản 6.5 gốc nhiều năm không vá. H5 client thiếu nhiều chức năng (không xem được Licensing) |
| vCenter 6.5.0 b15259038 / b24045034 | SMB / FHN01 | |
| vCenter 7.0.3 b22837322 | SG02, FHN02 | |
| **Server đời mới chạy ESXi 6.5** [SL: nhiều khả năng ngoài HCL] | R650xs: FPTDC .178/.188, SMB .25, FHN01 .24/.25; R660xs: FHN01 .21 | Tương tự VDC .125 (R660xs chạy 6.7) |

### 2.5 🟠 Dung lượng datastore và VM đang tắt
| vCenter | Datastore ≥ 80% | VM tắt (provisioned) | VM tắt lớn nhất |
|---|---|---|---|
| FHN02 | **UnityHN02_LUN01 91%** (alarm CRITICAL từ **19/11/2025**, 1 năm chưa xử lý) | 13 VM, 2.8 TB | **Toàn bộ cụm PROD_IC**: App01/02, DB01–04, Elk (khoảng 2.5 TB) |
| FHN01 | Cust_SAN.BK 91%, Cust_SVR.01 86% (R-019) | 9 VM, 1.5 TB | VTB_uCRM_DB02 172.31.90.52 (418 GB), VTB_uCRMv4_MidDB .90.34 (312 GB), VTB_MID_App01/02 |
| FPTDC | VNXe2_BE_07 **88%**, VNXe2_BE_04 **85%**, VNXe2_BE_03 83% (warning từ 11/2021), datastore2 (1) 83% (local PCCE1, không có alarm) | **53 VM, 15.7 TB** (12.4 TB đã dùng, khoảng 30% dung lượng VM) | 02_b2oraiq1 4.2 TB, 02_b3oraiq2 3.25 TB, 02_b1b2_iqdb 2.18 TB, 04_oxacm3 1.11 TB |
| SMB | BASE_Customer_LUN01 81.5% (warning từ 21/07/2026) | 25 VM, 3.6 TB | BASE_Infra_SELKs 1.39 TB, Wazuh, LogSvr |
| SG02 | không có | 1 VM (template) | |

Tổng cộng khoảng **23.7 TB provisioned nằm ở VM đang tắt**. Phải xác nhận với chủ ứng dụng trước khi thu hồi, và chỉ xóa qua `change-request`.

## 3. Chi tiết từng vCenter

### 3.1 SG02: vcsa.sg02basebs.com (10.138.110.10), [[FSG01]]
- vCenter 7.0.3 b22837322. vCenter HA chưa cấu hình. Datacenter "Datacenter SG02", 1 cluster.
- **Skyline Health** báo Warning "detected issues" từ 24/03/2026, chưa ack. Trang Skyline Health không tải được nên chưa rõ nội dung.
- Cluster01: **vSphere HA OFF** (mọi failure response Disabled), **DRS OFF**, Proactive HA không khả dụng, **EVC Disabled**. 44 lần vMotion.

| Host | Model | CPU | ESXi | VM | RAM dùng / tổng | Uptime | NTP | Cert hết hạn |
|---|---|---|---|---|---|---|---|---|
| .21 (srv01) | R660xs | 2× Gold 6442Y (96 LP) | 7.0.3 b24411414 (Dell A25) | 32 | 280.6 / 382.5 GB (73%) | 567 ngày | Running, ≈0 | 05/05/2030 |
| .22 (srv02) | R660xs | 2× Gold 6442Y (96 LP) | 7.0.3 b24411414 | 37 | 254.6 / 382.5 GB (67%) | **13 ngày** | Running, ≈0 | 05/05/2030 |
| .23 (srv03) | R650xs | 2× Gold 5320 (104 LP) | 7.0.3 b24411414 | 30 | 207.6 / 383.2 GB (54%) | 309 ngày | Running, ≈0 | 18/01/2031 |

- Hardware Health: không có cảnh báo (.21: 111 sensor, .22: 111, .23: 125). Tác vụ đọc IPMI SEL **lỗi trên .21 và .23** ("Retrieve IPMI SEL request to host failed"), .22 thành công.
- Datastore (5):

| Datastore | Loại | Dung lượng | Trống | Dùng |
|---|---|---|---|---|
| Unity_DAE01_Backup02 | VMFS6 | 25 TB | 11.85 TB | 53%. **Cũng được mount ở vCenter FPTDC** (mục 3.2) |
| Unity_DAE01_Backup03 | VMFS6 | 17 TB | 8.62 TB | 49% |
| SVR01-local / SVR02-local / SVR03-local | VMFS6 / 6 / 5 | 318.5 / 318.5 / 439 GB | gần như trống | ≈ 1–4% |

  - [SL] Tên "Backup" và dung lượng 25 + 17 TB khớp với nhóm 10 đĩa NL-SAS 6 TB của Unity380XT. Như vậy VM PROD có thể đang chạy trên đĩa NL-SAS. Cần xác minh pool trên Unity.
- VM: 99 (98 bật, 1 tắt: `oracle8.10-v1-26022025`). Provisioned 21.5 TB, used 21.2 TB.
  - Lớn nhất: HDS_Rec01_File / HDS_Rec02_File 3.07 TB mỗi VM, BASE_Ketoan 769 GB, Infra_VCSA 720 GB, PROD_Calabrio_WebCore 708 GB.
  - CPU cao nhất: HDS_Rec02_DB khoảng 9.9 GHz; HDS_Cn247s_DB02 / DB01 khoảng 4.2 / 3.6 GHz. Như vậy cụm HDS Cn247s ở SG02 có tải thực, không chỉ là "standby".
- **SG03 chạy trên SG02:** cây inventory có đầy đủ VM 10.148.x: Infra-AD-SG03BASEBS 10.148.120.20, Infra-RootCA / SubCA, Infra_NAS 10.148.80.200, PROD_Cn247_*, PROD_CUCM_PUB / SUB01 / SUB02, PROD_ExpressC / E, Calabrio, Recording, ExtProxy. → **Compute của SG03 nằm ở Cluster01 SG02 tại FSG01** (trả lời một phần Q3 / K13).
- **Sự cố đêm 11–12/11** (chưa có trong hồ sơ RCA):
  - .22 uptime 13 ngày. Hardware Health ghi lần cập nhật sensor cuối lúc **12/11 03:04:53**.
  - Event của .22: lúc 12:42:52 ngày 12/11 có "system clock stepped … lost synchronization", tức giờ của host đã sai trước đó.
  - VM `Infra_VCSA_10.138.110.10` **đang chạy trên .22**. Event của VM: "Virtual machine is starting" lúc **09:51:34 ngày 12/11** (theo đồng hồ host, trước lần NTP step).
  - [SL] Host .22 reboot khoảng 03:00 ngày 12/11, trùng cuối cửa sổ vmnic của FPTDC .186 lên xuống (01:53–03:05). vCenter SG02 và các VM trên .22 nằm tắt tới khoảng 09:51 vì HA OFF.
- Event gần đây: alarm "Virtual machine memory usage" trên HDS_Rec02_App bật / tắt ngày 14/11 và 20/11.

### 3.2 FPTDC: vCenter 10.0.3.50, [[FSG01]]
- vCenter **6.5.0 build 5973321** (bản 2017). Issuer VMCA của host là `O=VCenterBASE`, tức SSO domain **VCenterBASE**. 1 datacenter, 3 cluster, 5 host, 164 VM + 10 template, 23 datastore, 17 network.
- Cả 3 cluster **BACKEND, DMZ, PCCE1: vSphere HA Disabled, DRS Disabled**.

| Host | Cluster | Model | CPU | ESXi | VM | RAM dùng / tổng | Uptime | NTP | Cert hết hạn |
|---|---|---|---|---|---|---|---|---|---|
| 10.0.3.178 | **DMZ (1 host)** | R650xs | 2× Silver 4314 (64 LP) | 6.5.0 b19092475 | **55** | 240.3 / 383.2 GB (63%) | 1,155 ngày | **Disabled / Stopped, ≈ +7 phút** | 25/09/2028 |
| 10.0.3.186 | BACKEND | UCS C240 M4S | 2× E5-2695 v4 (72 LP) | **5.5.0 b2068190** | 53 | 171.9 / 383.9 GB (45%) | **13 ngày** (sự cố 11/11) | Running (10.0.3.47, .39), ≈ −20 s | (5.5: không hỗ trợ) |
| 10.0.3.188 | BACKEND | R650xs | 2× Silver 4314 (64 LP) | 6.5.0 b19092475 | 38 | 166.4 / 383.2 GB (43%) | 1,126 ngày | **Disabled / Stopped, ≈ −8 phút** | 11/10/2028 |
| 10.138.139.2 | PCCE1 | UCS C240 M4SX | 2× E5-2660 v3 (40 LP) | **5.5.0 b1746018** | 9 | 87.0 / 127.7 GB (68%) | **3,668 ngày** | Running, ≈0 | — |
| 10.138.139.3 | PCCE1 | UCS C240 M4SX | 2× E5-2660 v3 (40 LP) | **5.5.0 b1746018** | 9 | 101.2 / 127.7 GB (79%) | 3,190 ngày | Running, ≈0 | — |

- [SL] Cert của .188 hết hạn 11/10/2028, sớm hơn 5 năm kể từ ngày cấp. Nhiều khả năng CA gốc VMCA của vCenter này hết hạn cùng ngày; cần kiểm tra trước 2028.
- **Triggered alarms (9)**:

| Đối tượng | Alarm | Mức | Từ | Ack |
|---|---|---|---|---|
| VNXe2_BE_07 | Datastore usage on disk | Critical | 24/07/2026 | Chưa |
| VNXe2_BE_04 | Datastore usage on disk | Critical | 09/10/2025 | Chưa |
| VNXe2_BEFlash_02 | Datastore usage on disk | Warning | 30/09/2026 | Chưa |
| VNXe2_BE_06 | Datastore usage on disk | Warning | 12/03/2025 | Chưa |
| VNXe2_BE_03 | Datastore usage on disk | Warning | **04/11/2021** | Chưa |
| **10.138.139.2** | **Network uplink redundancy lost** | Critical | **26/08/2026** | **Ack 12/11/2026 (tinn)** → đang bị ẩn khỏi All Issues |
| 10.0.3.50 | Expired vCenter Server license | Critical | 16/12/2018 | Ack 17/12/2018 (tuevnq) |
| 09_eportal1_138.137.122 | VM Consolidation Needed | Warning | 17/01/2025 | Ack 06/02/2025 (vinhlq) |
| datastore2 (2) | Datastore usage on disk | Warning | 26/09/2019 | Ack 22/11/2019 (tuevnq) |

- License vCenter: H5 client 6.5 không có trang Licensing, nên **chưa xác minh**. vCenter vẫn quản lý host bình thường, nên [SL] license đã được gán sau 2018 và alarm chỉ còn treo. Cần xác minh bằng PowerCLI hoặc Flex client.
- **Datastore (23)**:

| Nhóm | Datastore (dùng %) |
|---|---|
| VNXe3200 #2 | VNXe2_BE_03 83%, BE_04 **85%**, BE_05 46%, BE_06 77%, BE_07 **88%**, BEFlash_01 72%, BEFlash_02 75% |
| Unity380XT | Unity380_LUN1 70% (10 TB), Unity380_LUN2 75% (10 TB), Unity380_LUN_Backup 73% (22 TB), **Unity_DAE01_Backup02 53% (25 TB, dùng chung với SG02)** |
| Local PCCE1 | datastore1 (3) 55%, datastore1 (4) 38%, datastore1 (5) 0%, datastore2 (1) **83%**, datastore2 (2) 79%, datastore3 49%, datastore3 (1) 54%, datastore4 27%, datastore4 (1) 35% |
| Local khác | esx05_local / esx06_local 2.18 TB gần như trống; Local186 278 GB trống |

  - **Không có datastore nào của VNXe3200 #1 (10.0.4.11)** trong vCenter này.
- **VM (164):** 111 bật, 53 tắt (1 VM tắt ở trạng thái Warning: 09_eportal1, cần consolidate). Provisioned 49.0 TB / used 41.7 TB.
  - VM tắt chiếm 15.7 TB provisioned. Một số VM tắt có ghi chú trong tên: `UCCX_VOICEGW_10.138.173.56-Khong duoc poweron`, `03_b1aes1_…_OFF`, `05_webi_…-del`.
  - Có 1 VM tên dạng đường dẫn `/vmfs/volumes/6819f130-…/oracle8.10-v1/oracle` (tắt, 64.28 GB). [SL] Cùng tên và dung lượng với template `oracle8.10-v1-26022025` ở SG02, tức **cùng một VM được đăng ký ở 2 vCenter** qua datastore dùng chung.
  - VM lớn trên .186: BASE_BE07_FREENAS_10.0.3.22 **10.07 TB** (VM NAS).

### 3.3 SMB: vcsa.smbbasebs.com (10.189.110.10), [[FSG02]]
- vCenter 6.5.0 b15259038 (banner "FDC SMB"). Datacenter "SMB", Cluster-01. 3 host, 109 VM + 7 template, 6 datastore, 15 network.
- **K14 và K16 đã giải:** vCenter SMB là 10.189.110.10, cluster chỉ có **3 host (.21, .22, .25)**. Host .23 / .24 không có trong vCenter.
- Cluster-01:
  - **vSphere HA ON** (master .22), nhưng **Host failure = Disabled ("VM restart priority disabled. VMs are not restarted in the event of a host failure")**.
  - Host isolation, PDL, APD, VM monitoring: Disabled.
  - Admission control: giữ lại 41% CPU / 43% RAM.
  - **DRS Disabled, EVC Disabled** (Gold 6252 Cascade Lake + Silver 4314 Ice Lake).

| Host | Model | CPU | ESXi | VM | RAM dùng / tổng | Uptime | NTP | Cert hết hạn |
|---|---|---|---|---|---|---|---|---|
| .21 | R740 | 2× Gold 6252 (96 LP) | 6.5.0 b13635690 | 30 | 215.3 / 255.5 GB (**84%**) | 2,443 ngày | client Disabled, service Running → **≈ −4 giờ 13 phút** | 27/02/2030 |
| .22 | R740 | 2× Gold 6252 (96 LP) | 6.5.0 b13635690 | 29 | 219.1 / 255.5 GB (**86%**) | 1,074 ngày | Enabled, service **Stopped** → **≈ −2 giờ 24 phút** | 27/02/2030 |
| .25 | R650xs | 2× Silver 4314 (64 LP) | 6.5.0 b19092475 | 50 | 337.8 / 383.2 GB (**88%**) | 1,381 ngày | Disabled / Stopped → **≈ +8 giờ 01 phút** | 12/02/2028 |

- **N+1 không đạt:** đang dùng 772 GB. Mất .25 thì còn 511 GB; mất 1 R740 thì còn 639 GB.
- Datastore (VMFS5):

| Datastore | Dung lượng | Trống | Dùng |
|---|---|---|---|
| BASE_Customer_LUN01 | 15 TB | 2.78 TB | **81.5%** (Warning từ 21/07/2026, chưa ack) |
| BASE_Backup_LUN01 | 7 TB | 2.74 TB | 61% |
| BASE_Infra_LUN01 | 5 TB | 2.23 TB | 55% |
| AppSvr.01 / .02 / .05-Datastore | 439 GB mỗi cái | gần như trống | local |

- Alarm: chỉ có BASE_Customer_LUN01.
- VM (109): 84 bật, 25 tắt. Provisioned 18.7 TB / used 18.4 TB; VM tắt 3.6 TB.
  - **Đang tắt:** BASE_Infra_SELKs 10.189.110.30 (1.39 TB), **BASE_Infra_Wazuh 10.189.120.22**, BASE_Infra_LogSvr 10.189.120.24, CN247_ExpressC_SUB 10.189.182.55, CN247_ExpressE_SUB 10.189.184.26, PROD_ReverseProxy01 10.189.184.51, PROD_UnifyCRM_App03, PROD_Restore02.
  - → Giám sát bảo mật (Wazuh, SELKs, log) và dự phòng Expressway / reverse proxy của Connect247 có vẻ đang không chạy. Cần xác nhận có chủ ý không.
  - CPU cao: BASE_Gitlab_runner03 khoảng 13 GHz; PROD_Rec_FreeSW, PROD_Cn247_Agent, PROD_Cn247_Db03 khoảng 3.1–3.2 GHz.

### 3.4 FHN01: vcsa.ccxbasebs.com (10.179.110.10), bổ sung cho số liệu 24/11 ([[FHN01]])

| Host | Cluster | Model | CPU | ESXi | VM | RAM | Uptime | NTP |
|---|---|---|---|---|---|---|---|---|
| .21 | A-App | R660xs | Gold 6442Y (96 LP) | 6.5.0 b20502893 | 28 | 72% | 355 ngày | Running, ≈0 |
| .22 | A-App | R640 | Gold 5220 (72 LP) | 6.5.0 b17477841 | 21 | 71% | 539 ngày | **Stopped, server 10.189.120.20 (SMB), ≈ +7 giờ 58 phút** |
| .23 | A-App | R640 | Gold 5220 | 6.5.0 b17477841 | 28 | 70% | 1,831 ngày | Running, ≈0 |
| .24 | A-App | R650xs | Gold 5320 (104 LP) | 6.5.0 b17477841 | 31 | 62% | 1,488 ngày | Running, ≈0 |
| .25 | A-App | R650xs | Silver 4314 (64 LP) | 6.5.0 b17477841 | 41 | 74% | 1,440 ngày | Running, ≈0 |
| .26 | A-App | R640 | Gold 5220 (72 LP) | 6.5.0 b19092475 | 34 | 69% | 1,034 ngày | Running, ≈0 |
| .45 | PCCE Cluster03 (PCCE3-A) | BE7H-M5 | Gold 6132 (56 LP) | 6.5.0 b8294253 | 8 | 48% | 706 ngày | **Stopped, ≈ −25 phút** |
| .47 | PCCE Cluster03 (PCCE3-B) | BE7H-M5 | Gold 6132 (56 LP) | 6.5.0 b8294253 | 7 | 43% (Alert quạt) | 1,165 ngày | **Stopped, ≈ −19 phút** |
| .53 | A-CCX | BE7M-M5 | Gold 6132 (28 LP) | 6.5.0 b8294253 | 3 | 36% | 2,871 ngày | **Disabled, ≈ −1 giờ** |

- A-App Cluster trộn **3 đời CPU** (Cascade Lake, Ice Lake, Sapphire Rapids) và **3 build ESXi 6.5**, trong khi EVC tắt. Host R660xs chạy ESXi 6.5.
- Triggered alarms (3, khớp 24/11): Cust_SVR.01 Critical (19/11/2026); Cust_SAN.BK Critical (12/01/2026); **.47 Host hardware fan status Critical từ 19/12/2024, ack 13/06/2025**.
- VM (201): 192 bật, 9 tắt. Provisioned 67.6 TB / used 66.9 TB.
- **Đối chiếu VM VietinBank (giải Q19, một phần Q20):**
  - **uCRM v4:** DB01 / DB02 / DB03 = 172.31.90.31 / .32 / .33 (bật); MidDB 172.31.90.34 (**tắt**); Report .90.42, pgBackRest .90.44 (bật).
  - **uCRM cũ:** VTB_uCRM_DB02 172.31.90.52 (**tắt**), VTB_uCRM_DB05 172.31.90.55 (bật); App02 .185.52, App03 .185.54, Elasticsearch .185.53, Redis .185.55–57 (bật).
  - **uCRM v5 đã dựng bản Std:** VTB_uCRMv5_App01 172.31.185.80 và VTB_uCRMv5_DB01 172.31.90.101, đều bật.
  - Đang tắt: VTB_MID_App01 / 02 (172.31.182.51 / .52), UAT_CRM_DB02 / 03.

### 3.5 FHN02: vcsa.hn02basebs.com (10.199.110.10), bổ sung cho số liệu 24/11 ([[FHN02]])

| Host | Model | CPU | ESXi | VM | RAM | Uptime | NTP | Cert hết hạn |
|---|---|---|---|---|---|---|---|---|
| .21 | R650xs | Gold 5320 (104 LP) | 7.0.3 b23307199 | 36 | 71% | 982 ngày (HA Primary) | Running, ≈0 | 13/03/2029 |
| .22 | R650xs | Gold 5320 (104 LP) | 7.0.3 b23307199 | 43 | **84%** | 982 ngày | Running, ≈0 | 13/03/2029 |
| .23 | R660xs | Gold 6442Y (96 LP) | 7.0.3 b24411414 | 37 | 67% | 463 ngày | Running, ≈0 | 17/08/2030 |

- Có VM NTP riêng: `BASE_Infra_NTP_10.199.120.21`.
- Triggered alarm: chỉ có **UnityHN02_LUN01 Critical từ 19/11/2025** (1 năm, chưa ack).
- VM (116): 103 bật, 13 tắt. Provisioned 39.0 TB / used 38.3 TB. VM tắt 2.8 TB, gồm **toàn bộ cụm PROD_IC**: PROD_IC_App01 / 02 (10.199.187.51 / .52), PROD_IC_DB01–04 (10.199.90.102–105), PROD_IC_Elk 10.199.187.59 (khoảng 2.5 TB), cùng PROD_AICC_CalDB01 10.199.90.34, HDS_Rec_Int02 và 3 template.
- → Nếu cụm IC đã ngừng dùng thì thu hồi được khoảng 2.5 TB, đúng chỗ đang thiếu (LUN01 91%, xem R-020 / R-022).

## 4. So với tài liệu và lần trước
| Hạng mục | Tài liệu / lần trước | Live 25/11 | Kết luận |
|---|---|---|---|
| SMB vCenter / số host (K14, K16) | .110.10?, 3–5 host | .110.10; 3 host (.21 / .22 / .25) | ✅ Giải |
| SG03 đặt ở đâu (Q3) | Chưa rõ | VM 10.148.x chạy trên SG02 Cluster01 (FSG01) | ✅ Giải phần compute |
| Host SG02 .21–.23 | 7.0.3, R660xs ×2 + R650xs, VM "?" | Khớp; 32 / 37 / 30 VM | ✅ + bổ sung |
| FPTDC 5 host / 164 VM, ESXi 5.5 / 6.5 | x01 (22/11) | Khớp; thêm build, NTP, alarm đã ack | ✅ + bổ sung |
| DB VTB v4 (Q19) | .51–.53 (x18) hay .32 | v4 = .31–.33; .52 / .55 thuộc cụm uCRM cũ | ✅ Giải |
| FSG01 "2 vCenter trong 1 site" | [VAULT] | Đúng; còn **dùng chung datastore** Unity_DAE01_Backup02 giữa 2 vCenter | ➕ Mới |
| Sự cố 11/11 chỉ ở FPTDC | [[2026-11-11-FPTDC-host186-LUN-loss]] | SG02 .22 cũng reboot; vCenter SG02 bật lại khoảng 09:51 ngày 12/11 | ➕ Mới, cần đưa vào RCA |
| NTP | Chỉ biết VDC | 9/23 host lệch ≥ 7 phút | ➕ Mới |

## 5. Đề xuất (mọi việc thay đổi cấu hình đều qua `change-request`)
**P1: tuần này**
1. **NTP toàn hệ thống** (ưu tiên số 1):
   - Mỗi site một CR. Thứ tự: SMB và FHN01 PCCE3 trước.
   - Nội dung: đặt đúng NTP server theo site (FHN01 .22 phải trỏ 10.179.120.20, không phải .189.120.20), mở firewall `ntpClient`, start `ntpd`, policy "Start and stop with host".
   - Host lệch hàng giờ: nên chỉnh giờ tay về gần đúng trước khi bật NTP, vì ntpd có thể từ chối đồng bộ khi độ lệch quá lớn.
   - **Trước khi chỉnh:** kiểm tra VM nào bật "Synchronize guest time with host" và kế hoạch backup / snapshot trong cửa sổ, tránh để guest nhảy giờ.
   - Với PCCE3 VietinBank: phối hợp `cc-echo` / skill `pcce-troubleshooting`, làm trong cửa sổ bảo trì, kiểm tra giờ trong các VM PCCE trước.
2. **SMB Cluster-01:**
   - Thực tế đang **không có HA**.
   - Bật "Host failure → Restart VMs" chỉ có ý nghĩa khi đủ RAM. Cần song song: nâng RAM 2 host R740 (256 GB), hoặc thêm host, hoặc thu hồi VM tắt / thừa.
   - Đặt restart priority cho vCenter, AD, DB, proxy.
3. **SG02 Cluster01:**
   - CR bật HA (admission control khoảng 33%), đặt `Infra_VCSA` priority cao nhất.
   - Cân nhắc VM-Host rule để vCenter không nằm chung host với VM quan trọng nhất.
   - N+1 hiện 97%: đủ nhưng sát.
4. **Sự cố 11/11:** bổ sung SG02 .22 vào [[2026-11-11-FPTDC-host186-LUN-loss]].
   - Thu log `vobd` / `vmkernel` / `hostd` của SG02 .22 quanh 12/11 00:00–10:00, nhớ hiệu chỉnh giờ.
   - Hỏi DC FPT về thao tác trong rack DC4 đêm 12/11 01:53–03:05.
   - Khi dùng log cục bộ của .178 / .188 phải cộng / trừ 7–8 phút.
5. **FPTDC .139.2 (PCCE1):** "Network uplink redundancy lost" từ 26/08 (đã ack 12/11). Kiểm tra vmnic / switch port; PCCE1 đang chạy trên 1 uplink.
6. **Dung lượng:** lập danh sách VM tắt cùng chủ ứng dụng (FHN02 cụm PROD_IC 2.5 TB trên LUN01 91%; FPTDC 15.7 TB; SMB 3.6 TB). Backup hoặc lưu trữ, rồi xóa qua CR. Ưu tiên FHN02 LUN01 và FPTDC VNXe2_BE_07 / BE_04.

**P2: lộ trình**
7. **Nâng cấp:**
   - vCenter 6.5 ×3 và 7.0 ×2 → 8.0 U3.
   - ESXi 5.5 / 6.5 → thay host hoặc nâng cấp theo HCL. Kiểm tra yêu cầu Cisco UC / PCCE và Avaya trước.
   - FPTDC PCCE1 (ESXi 5.5, chạy 10 năm) cần kế hoạch riêng.
8. **EVC:**
   - Mỗi cluster chọn EVC mode theo đời CPU thấp nhất, trong giới hạn bản vCenter hỗ trợ: SG02 / FHN02 → đời Ice Lake (Gold 5320); SMB và FHN01 A-App → đời Cascade Lake (Gold 6252 / 5220). vCenter 6.5 có thể chưa có mode Cascade Lake, khi đó phải chọn mode thấp hơn hoặc nâng vCenter trước.
   - Phải tắt VM trên host đời mới khi bật EVC, nên lên lịch theo đợt.
9. **FPTDC DMZ chỉ 1 host (55 VM):** đánh giá gom .178 với .188 (cùng model R650xs) hoặc bổ sung host, kèm HA.
10. **Datastore dùng chung 2 vCenter** (Unity_DAE01_Backup02): chốt vCenter sở hữu; gỡ đăng ký bản trùng của template oracle8.10.
11. Xác minh license vCenter FPTDC; xem nội dung Skyline Health SG02; xác nhận VM bảo mật SMB (Wazuh, SELKs, LogSvr) tắt có chủ ý không.
12. **Read-only tiếp theo:**
    - Chạy `Invoke-VSphereHealthCheck.ps1` (PowerCLI) cho 6 vCenter để lấy snapshot và VMware Tools từng VM (UI không xem được hàng loạt).
    - Đăng nhập LAB 172.23.90.10 để rà nốt.
    - Kiểm tra `ntpq -p` trên .186 và các host Running.

## 6. Giới hạn của lần rà này
- Chưa xem: snapshot và VMware Tools theo từng VM; cấu hình network (vSwitch / uplink) từng host; hardware sensor của FPTDC / SMB / FHN (chỉ dựa vào alarm); VAMI / health của các vCenter appliance; license; event cũ hơn khoảng 90 event gần nhất mỗi host; datastore nào mount trên host nào.
- Số "Consumed Memory %" là giá trị tức thời lúc đọc.
- Số liệu FHN01 / FHN02 về RAM tổng và datastore lấy từ lần đọc 24/11 ([[2026-11-24-ket-noi-FHN01-FHN02-app-db]]).
