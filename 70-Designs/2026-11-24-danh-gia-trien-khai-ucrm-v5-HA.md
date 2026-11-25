---
type: design
status: draft
updated: 2026-11-24
tags: [design, ucrm-v5, patroni, postgresql, ha, fhn01, fhn02, capacity]
---
# Đánh giá Compute / Storage / Network và mô hình triển khai uCRM v5 HA

> 📂 **Bộ tài liệu hiện hành (mô hình E', 2026-11-24):**
> - Excel kỹ thuật: `70-Designs/2026-11-24-VTB-uCRMv5-HA-modelE-trien-khai.xlsx` (12 sheet, gồm tài nguyên Duy Tân / PVB; chỉ 2 site).
> - Excel TGĐ: `70-Designs/2026-11-24-De-xuat-uCRMv5-HA-TGD.xlsx`.
> - Bản TGĐ (Claude Docs): https://claude.ai/artifact/DD863y73rxzYmu4qpduamZ
> - ⛔ `2026-11-24-VTB-uCRMv5-HA-PVB-trien-khai.xlsx` = mô hình D, **LỖI THỜI**.
>
> 🔴 **ĐÁNH GIÁ LẠI (2026-11-24, sau ràng buộc mới): mô hình D (chuyển toàn bộ sang PVB) KHÔNG còn được khuyến nghị.** Xem §8. Khuyến nghị mới: **mô hình E**, HA đặt tại Duy Tân theo 2 giai đoạn, tận dụng tài nguyên giải phóng từ CRM v4; PVB chỉ giữ bản sao dự phòng (DR).
>
> ⚠️ **Quyết định của chủ vault (2026-11-24): KHÔNG nâng cấp phần cứng, chỉ tận dụng tài nguyên sẵn có.** Các đề xuất "nâng RAM" và "mở rộng Unity380" ở §5.3, §6.3b và §7 chuyển thành **giới hạn chấp nhận**, xử lý bằng các biện pháp tận dụng:
> - dọn 7 VM IC (khoảng 2.4 TB);
> - data disk thin (đủ khoảng 19 tháng);
> - cân bằng host .22;
> - HA restart priority cho uCRM v5;
> - tắt hoặc thu nhỏ VM không cần thiết.
>
> **Rủi ro còn lại:** mất 1 host PVB thì RAM thiếu khoảng 164 GB; khoảng 19 tháng nữa cần đánh giá lại dung lượng lưu trữ.
>
> 📄 **Bản cho TGĐ (ngôn ngữ phổ thông, Claude Docs):** https://claude.ai/artifact/DD863y73rxzYmu4qpduamZ
>
> 📊 **Bảng tính chi tiết (có công thức):** `70-Designs/2026-11-24-VTB-uCRMv5-HA-PVB-trien-khai.xlsx`. Gồm 12 sheet: hiện trạng, mô hình, bố trí VM, capacity, tăng trưởng, IP plan, firewall, cấu hình, triển khai, test failover, rủi ro.

> Liên quan: [[2026-11-24-ket-noi-FHN01-FHN02-app-db]] (phân tích chi tiết) · [[FHN01]] · [[FHN02]] · [[VietinBank]] · [[risk-register]]
>
> **Nguồn:**
> - **[Live]** vSphere Client do Claude đọc read-only ngày 2026-11-24: vcsa.ccxbasebs.com (Duy Tân), vcsa.hn02basebs.com (PVB).
> - **[Ngân]** tài liệu "Đánh giá Storage & phương án triển khai uCRM v5 – vCenter HN02" (23/11/2026, `00-Inbox`).
> - **[Email]** thread "Hỗ trợ về việc kết nối giữa 2 site FPT Duy Tân - FPT Phạm Văn Bạch !" (18–23/11).
> - Số liệu PVB từ [Live] và [Ngân] **khớp nhau** nên được gắn nhãn [2N].
>
> **Yêu cầu:** uCRM v5 chạy HA với **2 App + 3 DB PostgreSQL (Patroni)**. Ràng buộc: **Duy Tân không dựng thêm được DB, chỉ dùng SAN, không dùng local disk.**

---

## 1. Hiện trạng Duy Tân (FHN01): vì sao không dựng thêm App HA / DB được

| Hạng mục | Hiện trạng | Hệ quả với uCRM v5 HA | Nguồn |
|---|---|---|---|
| **Storage SAN** | Unity300. **Cust_SVR.01 dùng 86% (còn 2.16 / 15 TB)**, **Cust_SAN.BK dùng 91% (còn 4.39 / 49.53 TB)**, cả hai alarm CRITICAL (Cust_SVR.01 mới từ 19/11). Unity300 hỏng đĩa liên tục 2024–2025, **slot 12 chưa có đĩa thay** | Thêm 1 node DB (600 GB) sẽ đẩy LUN vào vùng đỏ. Array đang suy giảm độ dư thừa. **Không đặt thêm DB được** | [Live] + x14 / x17 |
| **Local disk** | Có (SvrApp.0x-Local), nhưng **không được dùng** theo chính sách | Không thể dùng local để lách giới hạn SAN | Chủ vault |
| **vSphere HA** | **A-App Cluster: HA OFF, DRS OFF, EVC off** | Host chết thì VM không tự khởi động lại. HA ở tầng ứng dụng chạy trên nền không có HA ở tầng hạ tầng | [Live] |
| **Compute** | RAM A-App 70% (còn khoảng 650 GB), CPU khoảng 11% | Compute **không phải** là điểm nghẽn | [Live] |
| **Nền tảng** | vCenter / ESXi **6.5 (EOL)**; host .47 PCCE3-B **lỗi quạt từ 12/2024** (alarm bị ack, đang ẩn) | Rủi ro vận hành và hỗ trợ cao | [Live] |
| **uCRM v5 hiện có** | `VTB_uCRMv5_App01_172.31.185.80` (OL7, 8 vCPU / 8 GB / 60 GB, host .21) + `VTB_uCRMv5_DB01_172.31.90.101` (OL7, 8 vCPU / 16 GB / 600 GB, **144 GB đã dùng**, host .22). Tải rất thấp (DB: 43 MHz, 2 GB active) | Hệ thống mới, phù hợp chuyển kiến trúc **trước go-live** | [Live] |

**Kết luận phần 1:** Duy Tân **còn RAM nhưng đã hết storage**, và **không có HA ở tầng hạ tầng**. Dựng HA cho App và DB tại Duy Tân **không khả thi** nếu không mở rộng Unity300 (đang suy giảm) hoặc giải phóng dung lượng lớn.

---

## 2. Hiện trạng PVB (FHN02)

| Hạng mục | Hiện trạng | Nhãn |
|---|---|---|
| vSphere | vCenter / ESXi **7.0.3**, cluster AppSvrs 3 host, **HA ON** (admission control 33% RAM), DRS ON (**Manual**), EVC off | [2N] |
| Compute | CPU 12–19% mỗi host. RAM **858 / 1,149 GB (75%)**: .21 72% (còn 108 GB), **.22 84% (còn 60 GB)**, .23 68% (còn 123 GB) | [2N] |
| **N+1 RAM** | **Không đạt**: mất 1 host thì còn khoảng 766 GB so với 858 GB đang dùng, **thiếu khoảng 92 GB** (tính 858 − 766; [Ngân] ghi khoảng 140 GB, có thể đã tính thêm overhead) | [2N] |
| Storage | Unity380. **LUN01 91.1% (còn 3.36 / 37.81 TB), alarm**: 95 VM; ghi âm HDS_Rec khoảng 12 TB + Calabrio khoảng 6.8 TB chiếm gần nửa. **LUN02 44.5% (còn 5.55 / 10 TB)**. Local 3 × 318 GB (không dùng). Gần như toàn bộ VM thick; khoảng 650 GB file không thuộc VM nào | [2N] |
| uCRM v5 hiện có | **uCRMv5_APP (68 GB) + uCRMv5_DB "mono" (208 GB)** trên host .23 / LUN02 | [Ngân] |

---

## 3. Bảng đánh giá Compute / Storage / Network theo site

| Tiêu chí | Duy Tân (FHN01) | PVB (FHN02) | Ghi chú |
|---|---|---|---|
| **Compute: CPU** | 🟢 Dư (khoảng 11%) | 🟢 Dư (12–19%) | Không phải điểm nghẽn |
| **Compute: RAM** | 🟢 Còn khoảng 650 GB | 🟡 Còn khoảng 291 GB, **N+1 thiếu khoảng 92 GB** | uCRM v5 HA cần thêm **64 GB** (dựng mới 5 VM; [Ngân] tính 44 GB với 3 VM) |
| **Compute: HA hạ tầng** | 🔴 HA / DRS OFF | 🟢 HA ON (DRS Manual) | |
| **Compute: phiên bản** | 🔴 6.5 (EOL) | 🟢 7.0.3 | |
| **Storage: dung lượng** | 🔴 86–91%, CRITICAL | 🟡 LUN01 91% (đỏ), **LUN02 44.5% (xanh)** | uCRM v5: kế hoạch Ngân **1.26 TB**; **sizing theo tăng trưởng thực tế khoảng 4.8 TB** (xem §6) |
| **Storage: sức khỏe array** | 🔴 Unity300 hỏng đĩa, thiếu đĩa thay | 🟢 Unity380 | |
| **Storage: chính sách** | Chỉ SAN | Chỉ SAN (LUN02) | Local disk bị loại ở cả 2 site |
| **Network: nội site** | 🟢 LAN | 🟢 LAN | App↔DB trong cùng site đạt độ trễ dưới 1 ms |
| **Network: liên site** | IPsec vòng qua hub VDC (HCM): **chưa đo**, ước tính 30–60 ms | Như bên trái | Kênh Metro FPT 100M: **16 tr/tháng + 5 tr lắp đặt**, chưa có SLA / độ trễ cam kết |
| **Network: dải IP** | VTB uCRM v5 trong 172.31.0.0/16 (PCCE3-DB, PCCE3-uCRM) | 10.199.0.0/16 | Nếu đưa instance VTB sang PVB thì cần subnet 172.31.x mới ở PVB (L3) cùng route / FW |

---

## 4. So sánh các mô hình triển khai

| Mô hình | Bố trí | Độ trễ App↔DB | HA khi mất 1 host | Khi mất 1 site | Quorum / split-brain | Tài nguyên thêm | Khả thi | Đánh giá |
|---|---|---|---|---|---|---|---|---|
| **A** | Tất cả ở Duy Tân (DB02 sync cùng site) + DB03 async ở PVB | LAN | ✅ Patroni | Failover tay | ✅ | Duy Tân +24 GB, +660 GB | ❌ **Duy Tân hết storage** | Loại |
| **B** | App01 + DB01 ở Duy Tân; App02 + DB02 + DB03 ở PVB, **primary ở Duy Tân**, không có witness | Cross-site nếu App02 active | ⚠️ | ⚠️ | 🔴 **etcd đa số ở PVB, đứt kênh thì primary ở Duy Tân tự demote** | PVB +44 GB | ⚠️ | Loại (lỗi thiết kế) |
| **C** | Như B nhưng có **witness etcd ở VDC**, replication async | LAN (App ở Duy Tân) | ⚠️ Mất DB01 thì promote sang PVB, App chạy chéo site (chậm) | Tự failover sang PVB | ✅ Có witness | PVB +32 GB / 1.2 TB, VDC +2 GB | ✅ | Tạm thời, nhiều điểm phụ thuộc vào kênh liên site |
| **D** ⭐ | **Toàn bộ HA ở PVB:** App 2 node + DB 3 node (Patroni) trên LUN02. Duy Tân: (tùy chọn) DB async replica làm DR / chuyển tiếp | **LAN** | ✅ **Patroni + vSphere HA** | Failover tay sang Duy Tân (nếu giữ DR replica) | ✅ etcd 3 member cùng site | PVB **+44 GB RAM / +1.26 TB** | ✅ | **Khuyến nghị** |

**Vì sao chọn D:**
- App↔DB và replication đồng bộ đều nằm trong LAN.
- Có HA ở cả hai tầng: Patroni và vSphere HA.
- Không phụ thuộc kênh liên site, nên **không cần thuê Metro 100M** cho bài toán HA (kênh chỉ cần nếu muốn có DR sang Duy Tân).
- **Trùng với kế hoạch Ngân đã khảo sát.**

---

## 5. Phương án D: chi tiết

### 5.1 Bố trí (theo [Ngân], bổ sung các điểm Patroni)
| VM | Vai trò | vCPU | RAM | Disk | Host | Datastore |
|---|---|---|---|---|---|---|
> Cập nhật 2026-11-24: PVB chưa có node nào của VTB v5, nên **cả 5 VM đều dựng mới**. Data disk DB khoảng 1.5 TB thin (§6.3b). Bảng gốc của [Ngân] giả định có sẵn "node 1" trên .23; giả định đó sai, vì .23 là uCRM của BaseBS.

| VM | Vai trò | vCPU | RAM | Disk | Host | Datastore |
|---|---|---|---|---|---|---|
| **VTB uCRMv5 App01-PVB (mới)** | App | 8 | 8–12 GB | 60 GB | .23 | LUN02 |
| **VTB uCRMv5 App02-PVB (mới)** | App | 8 | 8–12 GB | 60 GB | .21 | LUN02 |
| **VTB uCRMv5 DB01-PVB (mới)** | Patroni + etcd-1 | 8 | 16 GB | OS 60 GB + **data 1.5 TB thin** | .23 | LUN02 |
| **VTB uCRMv5 DB02-PVB (mới)** | Patroni + etcd-2 | 8 | 16 GB | OS 60 GB + data 1.5 TB thin | .21 | LUN02 |
| **VTB uCRMv5 DB03-PVB (mới)** | Patroni + etcd-3 | 8 | 16 GB | OS 60 GB + data 1.5 TB thin | .22 | LUN02 |

- **Tổng tăng thêm:** 40 vCPU, **khoảng 64–72 GB RAM** (cao hơn mức 44 GB của [Ngân] vì dựng mới cả 5 VM); disk thực dùng khoảng 1.7 TB lúc đầu.
- **RAM sau triển khai (ước tính):** .21 79.4%, .22 88.5%, .23 74.9%; cụm 80.9%. N+1 thiếu **khoảng 164 GB** (file Excel, sheet 5), nên **bắt buộc** cân bằng lại .22 và lập kế hoạch nâng RAM.
- 2 VM v5 đang build ở Duy Tân (DB01 172.31.90.101, App01 172.31.185.80): dùng làm môi trường build / test tới khi cụm PVB sẵn sàng, sau đó thu hồi.
- **Patroni:** `synchronous_mode: true` (1 sync standby), `maximum_lag_on_failover` theo RPO. App kết nối qua **HAProxy** (check `/primary` cổng 8008) hoặc libpq multi-host `target_session_attrs=read-write`.
- **App HA:** keepalived VIP hoặc LB trước 2 App node.
- **DRS rule "Separate Virtual Machines"** cho 3 DB và 2 App. Lưu ý DRS đang ở chế độ Manual: rule chỉ được áp dụng khi power-on hoặc khi duyệt đề xuất. Cần kiểm tra cách HA xử lý rule khi restart VM.
- **OS:** node mới dùng OL8/9; **PostgreSQL phải cùng major version** với DB node 1.

### 5.2 Đối tượng triển khai (chủ vault xác nhận 2026-11-24)
- **Đối tượng HA là VTB uCRM v5 đang build tại Duy Tân:** `VTB_uCRMv5_DB01` 172.31.90.101 và `VTB_uCRMv5_App01` 172.31.185.80. **Chưa go-live.**
- **172.31.90.32 là DB của CRM v4** (`VTB_CRMv4_DB_PG02`, [[_VTB-CRMv4-DB]]). **Không dùng v4 cho bản build mới**; v4 chỉ làm **tham chiếu sizing** (ảnh Checkmk Ngân gửi).
- **PVB hiện chưa có gì của VTB v5** (chủ vault xác nhận). Bộ "uCRMv5_APP / uCRMv5_DB" mà [Ngân] liệt kê trên host .23 là **uCRM của BaseBS** (ví dụ `PROD_uCRMv5_DB_10.199.90.65`, folder `UCRMv5` / `UCRMv4-VMs` / `UCRM-VMs`, dải 10.199.x; [Live] tìm "uCRM" thấy 17 VM). Đây **không phải "node 1" của VTB v5**, nên cụm VTB v5 ở PVB phải **dựng mới cả 2 App + 3 DB** (xem bảng ở §5.1: cần thay 2 dòng "có sẵn" bằng VM mới).
- **v5 sẽ nhận dữ liệu từ v4** (chủ vault xác nhận), tức áp dụng kịch bản (a) ở §6.2.
- **Vì v5 chưa go-live, đây là thời điểm rẻ nhất để dựng cụm HA trực tiếp ở PVB** thay vì nâng cấp tại chỗ ở Duy Tân:
  - dựng mới 2 App + 3 DB (Patroni) ở PVB, hoặc tái sử dụng node .23 nếu đúng là cùng hệ;
  - **cần subnet 172.31.x mới ở PVB** (L3, route / FW nội bộ VTB) hoặc quy hoạch lại IP;
  - 2 VM v5 đang build ở Duy Tân: giữ làm môi trường build / test cho tới khi cụm PVB sẵn sàng, sau đó thu hồi (hoặc làm async replica DR nếu sau này có kênh liên site).

### 5.3 Điều kiện tiên quyết (lấy từ [Ngân] và bổ sung)
| Ưu tiên | Việc | Lý do |
|---|---|---|
| **P1** | Giảm tải LUN01: xóa 7 VM `PROD_IC_*` đang tắt (khoảng 2.4 TB, **sau khi export OVF và được chủ hệ thống xác nhận**), Storage vMotion HDS_Rec_File02 / HDS_CalabrioDB02 / HDS_Rec_DB sang LUN02 (khoảng 1.84 TB). LUN01 từ 91.1% về khoảng 80% | LUN01 vượt ngưỡng đỏ |
| **P1** | Rà soát snapshot cả 2 LUN | Chưa kiểm tra |
| **P1** | vMotion khoảng 16 GB RAM ra khỏi host .22 | .22 sẽ lên khoảng 88% |
| **P2** | **Bổ sung RAM** (ví dụ +128 GB mỗi host) **hoặc thêm host thứ 4** | N+1 thiếu khoảng 92 GB, sau uCRM v5 thiếu khoảng 164 GB. Đề xuất +128 GB mỗi host (file Excel, sheet 5) |
| **P2** | Archive ghi âm (HDS_Rec_File 9.9 TB, CalabrioDFS01 5.2 TB) | Chiếm khoảng 44% LUN01 |
| **P3** | VMFS5 lên VMFS6 (UNMAP), mở rộng Unity nếu LUN02 vượt 75% | Dung lượng dài hạn |

⚠️ **Mâu thuẫn dung lượng LUN02:** theo [Ngân], **LUN02 sẽ lên khoảng 79%** sau khi nhận cả uCRM v5 (+1.26 TB), phần mở rộng DB node 1 (+0.4 TB) và 3 VM chuyển từ LUN01 sang (+1.84 TB). **Gần như không còn chỗ cho tăng trưởng** (xem mục 6).

---

## 6. Tăng trưởng dữ liệu (tham chiếu CRM v4, ảnh Checkmk của Ngân)

### 6.1 Số liệu thực tế của CRM v4 ([[_VTB-CRMv4-DB]], PG02 172.31.90.32, ngày 23/11/2026)
| Chỉ số | Giá trị |
|---|---|
| Filesystem `/` (chứa cả data PG) | **452 / 595 GiB (75.9%)**; DB size theo pgBackRest khoảng 427 GB |
| Tăng 35 ngày (19/10 → 23/11) | +51 GiB, tức **khoảng 1.46 GiB/ngày** |
| Checkmk trend / growth 35 ngày | 1.19 GiB/ngày; avg khoảng 1.70, max 4.37 GiB/ngày |
| Go-live v4 | 06/2026, nghĩa là **khoảng 450 GiB sau khoảng 5 tháng chạy** |

### 6.2 Dự báo cho uCRM v5 (giả định tải tương đương v4) [SL]
Có 2 kịch bản khởi điểm:
- **(a)** v5 nhận lại dữ liệu v4. Anh Phong có nhắc "replicate dữ liệu UCRM cũ sang UCRM mới, cài thêm DWH" ([Email] 23/11). Khi đó **khởi điểm khoảng 450 GiB**.
- **(b)** v5 bắt đầu từ dữ liệu mới, **khởi điểm khoảng 150 GiB** (DB01 hiện dùng 144 GB).

| Mốc | (a) Khởi điểm 450 GiB, tăng 1.46 GiB/ngày | (a) tăng 1.70 GiB/ngày | (b) Khởi điểm 150 GiB, tăng 1.46 GiB/ngày |
|---|---|---|---|
| +6 tháng | khoảng 715 GiB | khoảng 760 GiB | khoảng 415 GiB |
| +12 tháng | **khoảng 985 GiB** | **khoảng 1,070 GiB** | khoảng 685 GiB |
| +24 tháng | **khoảng 1,515 GiB** | **khoảng 1,690 GiB** | khoảng 1,215 GiB |

**Kết luận sizing:**
- **Disk 600 GB / node (theo kế hoạch của Ngân) không đủ.**
  - Với kịch bản (a), disk vượt ngưỡng 80% (480 GB) **ngay từ ngày go-live**.
  - Với kịch bản (b), disk chạm ngưỡng 80% sau khoảng 7 tháng.
- **Đề xuất mỗi node DB:** OS disk 60 GB, cộng **data disk riêng (/var/lib/pgsql) khoảng 1.5 TB** để đủ 12–24 tháng với ngưỡng 80%. Kèm theo:
  - tách WAL nếu cần;
  - **không để data chung với `/`**. Đây là bài học từ v4: PG02 đang để data trên `/`, đầy disk là chết cả OS.

### 6.3 Ảnh hưởng tới storage PVB (LUN02 10 TB, còn 5.55 TB)
| Hạng mục | Kế hoạch Ngân | Theo tăng trưởng thực tế |
|---|---|---|
| 3 DB node | 3 × 600 GB = 1.8 TB (thực tế 2 node mới = 1.2 TB) | **3 × (60 GB + 1.5 TB) khoảng 4.7 TB** |
| 2 App node | khoảng 0.13 TB | khoảng 0.13 TB |
| **Tổng uCRM v5** | **khoảng 1.26 TB** | **khoảng 4.8 TB** |
| LUN02 sau khi đặt uCRM v5 (chưa tính chuyển VM từ LUN01) | khoảng 57% | **khoảng 92%** 🔴 |
| Cộng thêm 3 VM chuyển từ LUN01 (+1.84 TB) | khoảng 79% | **vượt 100%** ❌ |

**Hệ quả:**
1. **LUN02 không chứa được** cụm v5 sizing đúng **cùng lúc** với kế hoạch giảm tải LUN01. **Bắt buộc phải mở rộng storage**: thêm LUN mới từ pool Unity380 (cần kiểm tra **dung lượng pool còn trống** trên Unisphere 10.199.110.9) hoặc mua thêm đĩa / expansion.
2. Giải pháp tạm: **thin provision data disk** (cấp 1.5 TB nhưng chỉ chiếm phần đã dùng). Cách này bắt buộc phải theo dõi datastore chặt; trái với thông lệ thick hiện tại.
3. Backup pgBackRest (full hằng tuần + incr hằng ngày, giữ khoảng 2 full) cần **khoảng 2–3 × DB size** ở repo. Cần xác định repo đặt ở đâu (không nên trên cùng Unity).

### 6.3b Năng lực Unity380 PVB thực tế ([Live] Unisphere CRK00240415710, 2026-11-24)
| Chỉ số | Giá trị |
|---|---|
| Pool `BASEBS_Prod` (pool duy nhất) | **50.8 TB**, **Free 2.6 TB**, **Subscription 94.9%**, Preallocated 0 |
| Datastore VMFS trên pool | UnityHN02_LUN01 38,720 GB và UnityHN02_LUN02 10,240 GB, **Allocated khoảng 100%** (đã chiếm hết dung lượng pool) |
| Hiệu suất | Khoảng 617 IOPS, khoảng 14 MB/s, SP 8.9% (4 giờ gần nhất): còn rất dư |
| Data reduction | 1:1 (không có tiết kiệm) |

**Tổng dung lượng còn có thể dùng cho VM mới mà không mua thêm phần cứng:**
- LUN02 trống 5.55 TB;
- pool trống 2.6 TB (mở rộng LUN02 hoặc tạo LUN mới; khi đó pool lên khoảng 100%);
- LUN01 trống 3.36 TB (nhưng LUN01 đã 91%, không dùng).

**Kịch bản xếp chỗ cho VTB v5 (2 App + 3 DB, kịch bản dữ liệu (a))**
| Phương án | Cách làm | LUN02 sau khi đặt | Ghi chú |
|---|---|---|---|
| S1: Thick 1.5 TB / node | 3 × 1.56 TB + 2 × 60 GB, khoảng 4.8 TB | **khoảng 92%** (còn khoảng 0.75 TB) | Không còn chỗ cho kế hoạch chuyển VM từ LUN01 (1.84 TB) của Ngân. Muốn làm thì phải dùng 2.6 TB còn lại của pool, nên **pool sẽ lên 100%** ❌ |
| **S2: Thin data disk (khuyến nghị tạm thời)** | Cấp 1.5 TB / node nhưng chỉ chiếm phần dữ liệu thực, khởi điểm khoảng 0.5 TB / node, tổng khoảng 1.7 TB | khoảng 61% (chưa tính VM chuyển từ LUN01); khoảng 79% nếu tính | Tăng khoảng 4.4 GiB/ngày (×3 node), khoảng 130 GB/tháng. Còn khoảng **12–15 tháng** trước khi LUN02 chạm 85%. **Bắt buộc**: alarm datastore 75/85% và theo dõi hằng tuần |
| S3: Mở rộng phần cứng | Thêm đĩa hoặc DAE cho Unity380, hoặc archive ghi âm (HDS_Rec_File 9.9 TB + CalabrioDFS01 5.2 TB) sang storage rẻ hơn | — | Cần ngân sách. **Nên lên kế hoạch trong vòng 12 tháng**, song song với S2 |

**Đề xuất storage:** S2 ngay (không cần mua thêm), kèm S3 trong vòng 12 tháng. Đồng thời giảm tải LUN01 **bằng cách xóa 7 VM `PROD_IC_*` (khoảng 2.4 TB, sau export và xác nhận)** thay vì chuyển VM sang LUN02, để giữ LUN02 cho v5.

### 6.4 Rủi ro song song: CRM v4 đang chạy PROD
CRM v4 (PG02) **sẽ chạm Warning 80% khoảng 09–13/12/2026, Critical 90% khoảng 19/01–01/02/2027, đầy khoảng 03/2027**. Nếu v5 chưa go-live và chưa chuyển dữ liệu kịp trước khoảng 01/2027 thì **phải mở rộng disk cho v4** (là change). Tiến độ v5 vì vậy bị ràng buộc bởi thời điểm v4 đầy disk.

---

## 7. Kết luận và đề xuất
1. **Duy Tân:** không dựng thêm App HA hoặc DB (hết storage, Unity300 suy giảm, không có vSphere HA). Giữ nguyên hiện trạng; nếu có kênh liên site thì cân nhắc dùng làm DR (async replica).
2. **Chọn mô hình D:** cụm uCRM v5 HA (2 App + 3 DB Patroni) đặt toàn bộ ở **PVB / LUN02**, theo bố trí của Ngân.
3. **Làm trước (điều kiện tiên quyết):** giảm tải LUN01, rà snapshot, cân bằng RAM host .22.
4. **Song song:** đề xuất **nâng RAM hoặc thêm host** cho PVB để khôi phục N+1, và **mở rộng Unity380** theo tốc độ tăng trưởng.
5. **Kênh Metro 100M không bắt buộc** cho mô hình D. Chỉ cần nếu muốn DR sang Duy Tân, hoặc để chuyển dữ liệu v4 sang v5 nhanh hơn (dùng IPsec cũng được, chỉ chậm hơn).
6. **Sizing lại DB node: khoảng 1.5 TB data disk / node** (không phải 600 GB). Pool Unity380 PVB **chỉ còn 2.6 TB** (subscription 94.9%), nên dùng **thin data disk trên LUN02** (khoảng 1.7 TB thực dùng lúc đầu, đủ cho khoảng 12–15 tháng) và **lập kế hoạch mở rộng Unity380 hoặc archive ghi âm trong vòng 12 tháng**. Giảm tải LUN01 bằng cách xóa VM IC (không chuyển VM sang LUN02).
7. **Mốc thời gian:** v4 đầy disk khoảng 03/2027 (Critical khoảng 01/2027). Hoặc v5 go-live trước mốc đó, hoặc mở rộng disk v4.
8. **Cần làm rõ:**
   - quan hệ giữa VTB v5 (Duy Tân) và bộ "uCRMv5 mono" trên PVB .23;
   - v5 có nhận lại dữ liệu v4 không (kịch bản a hay b);
   - PostgreSQL major version;
   - RPO / RTO;
   - dung lượng pool trống trên Unity380 PVB.
7. Mọi bước thay đổi (tạo VM, vMotion, xóa VM, mở rộng disk, cấu hình Patroni, cutover) đều đi qua **change-request**.

---

## 8. Đánh giá lại (2026-11-24): uCRM phụ thuộc PCCE3 và firewall VTB tại Duy Tân

### 8.1 Ràng buộc mới (chủ vault xác nhận)
- uCRM v5 **không phải ứng dụng độc lập**: nó tích hợp với các thành phần **PCCE3 tại Duy Tân** (CTI, CUCM, Finesse, các dịch vụ VTB khác).
- **Firewall phía VietinBank đã mở rule tới App và DB tại Duy Tân** (đi qua Metro VNPT/FPT kết cuối ở Duy Tân).
- Không nâng cấp phần cứng; chỉ tận dụng tài nguyên sẵn có.

### 8.2 Đánh giá việc chuyển 2 subnet 172.31.90.0/24 (DB) và 172.31.185.0/24 (uCRM) sang PVB: **KHÔNG KHUYẾN NGHỊ**
| Vấn đề | Chi tiết |
|---|---|
| **Subnet không chỉ chứa uCRM v5** | 172.31.90.0/24 còn chứa DB của CRM v4 (.31/.32/.33), Report (.42), MidDB (.34), LCM DB (.81–.83), MID / Ibox DB (.91/.92). 172.31.185.0/24 còn chứa uCRM v4 App01/02 (.70/.71), Es01 (.72), Share01 (.73), uCRM .51. Chuyển subnet nghĩa là chuyển **cả hệ sinh thái VTB**, hoặc phải tách subnet (re-IP) [Live vCenter + vault] |
| **Mọi traffic nghiệp vụ phải đi qua kênh liên site** | PCCE3 ↔ uCRM (screen-pop, CTI, mỗi cuộc gọi) và VietinBank ↔ uCRM (vào qua Metro ở Duy Tân) đều phải đi Duy Tân → PVB. Đứt kênh là **mất dịch vụ hoàn toàn**, dù cả 2 site đều đang chạy |
| **Bắt buộc có Metro, và Metro trở thành điểm lỗi đơn** | IPsec hiện có đi vòng qua HCM (khoảng 30–60 ms) không đủ cho tích hợp thời gian thực. FPT mới báo giá **1 kênh 100M, chưa có SLA, chưa có kênh dự phòng khác tuyến**. Chi phí 16 triệu/tháng, trái với hướng "chỉ tận dụng" |
| **Firewall VietinBank phải đổi** | Nếu đổi IP thì VTB phải mở rule mới (quy trình ngân hàng, VTB buộc phải biết). Nếu giữ IP thì phải **kéo dài L2 VLAN 90 / 185 qua Metro** (rủi ro broadcast hoặc STP giữa 2 DC, khó vận hành) |
| **Lợi ích thu được** | HA tốt hơn cho DB, nhưng đổi lại rủi ro ở tầng mạng lớn hơn rủi ro ban đầu |

→ **Kết luận:** mô hình D (và các biến thể chuyển subnet) **bị loại**. Đặt App và DB **cùng site với PCCE3 và điểm vào của VTB (Duy Tân)** là điều kiện bắt buộc.

### 8.3 Tài nguyên tận dụng được tại Duy Tân: phần dung lượng của CRM v4
[Live] vCenter Duy Tân, tìm "CRMv4": 13 VM.

| VM (PROD) | IP | Dung lượng | Ghi chú |
|---|---|---|---|
| VTB_uCRMv4_DB01 / DB02 / DB03 | 172.31.90.31 / .32 / .33 | 3 × 616 GB | Cụm Patroni v4 (PG02 = .32, primary theo Ngân) |
| VTB_uCRMv4_Report | 172.31.90.42 | 616 GB | |
| VTB_uCRMv4_App01 / App02 | 172.31.185.70 / .71 | 2 × 72 GB | |
| VTB_uCRMv4_Es01 | 172.31.185.72 | 262 GB | |
| VTB_uCRMv4_Share01 | 172.31.185.73 | 286 GB | |
| VTB_uCRMv4_MidDB | 172.31.90.34 | 300 GB | **Powered Off**: có thể thu hồi sớm nếu được xác nhận |
| **Tổng PROD v4** | | **khoảng 3.4 TB** | Giải phóng sau khi v5 cutover và thu hồi v4 |
| UAT_UCRMv4_* (4 VM) | 172.31.245.111–114 | khoảng 0.33 TB | UAT |

→ **v5 thay v4 trên cùng site.** Sau cutover, khoảng 3.4 TB SAN và các IP v4 (VTB đã mở firewall cho chúng) **được giải phóng ngay tại Duy Tân**. Dung lượng này lớn hơn mức cụm v5 HA cần (khoảng 1.6 TB thin ban đầu, khoảng 4.8 TB nếu thick). **Không cần mua gì, không cần chuyển site.**

### 8.4 Mô hình E, khuyến nghị: HA tại Duy Tân theo 2 giai đoạn, PVB làm DR
**Giai đoạn 1: go-live (trước khoảng 01/2027)**
| Site | Node | Vai trò |
|---|---|---|
| Duy Tân | App01 (có sẵn, .185.80) | App active; giữ IP, không đổi rule VTB |
| Duy Tân | DB01 (có sẵn, .90.101) | **Primary** Patroni + etcd-1 |
| PVB | DB02 (mới, LUN02, thin) | Replica **async** + etcd-2 (DR, bảo vệ dữ liệu) |
| VDC | etcd witness (VM nhỏ, 2 GB RAM / 20 GB) | etcd-3. Đứt kênh Duy Tân ↔ PVB thì Duy Tân + VDC vẫn giữ quorum, primary **không** bị demote |
- **Dịch vụ không phụ thuộc kênh liên site**: App, DB primary, PCCE3 và điểm vào VTB đều ở Duy Tân. Kênh liên site chỉ dùng cho replication và etcd, **IPsec hiện có là đủ** (WAL khoảng 1.5 GB/ngày).
- Mất host DB01: Patroni promote DB02 ở PVB, dịch vụ vẫn chạy nhưng **chậm** (App truy vấn qua kênh liên site). Đây là trạng thái tạm, chờ failback. Tốt hơn hiện trạng (hiện chỉ có 1 DB, ở cluster không bật HA).
- Điểm truy cập DB: HAProxy / VIP tại Duy Tân. **Đề xuất giữ địa chỉ mà VTB và PCCE3 đang dùng (172.31.90.101) làm VIP** (đổi IP thật của DB01) để không phải đổi rule VTB. Cần CR riêng [SL].
- Song song: migrate dữ liệu v4 sang v5 (cùng site Duy Tân, trong LAN, nhanh).

**Giai đoạn 2: sau cutover và thu hồi v4 (khoảng 02–03/2027)**
| Site | Node | Vai trò |
|---|---|---|
| Duy Tân | App01 + **App02** (dựng trên chỗ của v4 App) | App HA active-active + keepalived VIP |
| Duy Tân | DB01 primary + **DB03 (dựng trên chỗ của v4 DB)** sync standby | HA cùng site: failover khoảng 30 giây, trong LAN, không mất dữ liệu |
| PVB | DB02 | Async DR, `nofailover` hoặc priority thấp |
| etcd | DB01, DB03 (Duy Tân) + DB02 (PVB) | Bỏ witness VDC |
- **Tận dụng IP v4** (172.31.90.31–.33, 185.70–.71) cho node mới nếu rule VTB đã mở cho các IP này. Cần đối chiếu rule [SL].
- Kiến nghị kèm theo: **bật vSphere HA cho A-App Cluster** (R-017). Đây là cấu hình, không phải nâng cấp.

**Tài nguyên**
| Site | Giai đoạn 1 | Giai đoạn 2 |
|---|---|---|
| Duy Tân | Không thêm (dùng 2 VM v5 đang build) | Thêm App02 + DB03 khoảng 24 GB RAM, khoảng 0.6–1.6 TB, **lấy từ khoảng 3.4 TB thu hồi của v4** |
| PVB | DB02: 8 vCPU / 16 GB, thin khoảng 0.5 TB ban đầu trên LUN02 | Như giai đoạn 1 |
| VDC | Witness 2 GB RAM / 20 GB | Thu hồi |
| Kênh liên site | IPsec hiện có (async + etcd) | Như giai đoạn 1; Metro **tùy chọn** |

### 8.5 So sánh nhanh D và E
| Tiêu chí | D: toàn bộ sang PVB | **E: HA tại Duy Tân + DR ở PVB** |
|---|---|---|
| Đường đi PCCE3 / VTB → uCRM | Qua kênh liên site | **Trong LAN Duy Tân** |
| Phụ thuộc Metro | **Bắt buộc, điểm lỗi đơn** | Không (IPsec đủ cho replication) |
| Firewall VTB | Phải đổi (hoặc kéo dài L2) | **Không đổi** (giữ IP / VIP) |
| Chi phí | 16 tr/tháng Metro + 5 tr | **0** |
| Tài nguyên | PVB thiếu RAM N+1, LUN02 | Tận dụng chỗ của v4 ở Duy Tân sau cutover |
| HA DB | Cùng site, sync | GĐ1: chuyển sang PVB (chậm); **GĐ2: cùng site, sync** |
| Rủi ro còn lại | Mất Metro = mất dịch vụ | Duy Tân: cluster chưa bật HA, Unity300 suy giảm → bật HA, giám sát đĩa; PVB DR giữ bản sao dữ liệu |

### 8.6 Việc cần xác minh
1. Rule firewall VTB hiện có: theo IP nào (App01 .185.80, DB01 .90.101, hay cả dải)? Có bao gồm IP của v4 không? (Network / VTB)
2. Danh sách tích hợp uCRM v5 ↔ PCCE3 (CTI, CUCM, Finesse, SSO...) và port (Dev).
3. Thời điểm thu hồi v4 sau cutover (bao lâu chạy song song?) (Dev / anh Phong).
4. VM `VTB_uCRMv4_MidDB` (đang tắt, 300 GB): có thu hồi sớm được không?
5. Datastore cụ thể của các VM v4 (Cust_SVR.01 hay Cust_SAN.BK), để biết sau thu hồi LUN nào được giải phóng.

### 8.7 Cập nhật theo bảng mở firewall VTB và việc v4 chạy song song lâu dài (2026-11-24)
**Nguồn:** `00-Inbox/VTB_UCRMv4.1_network_rules_request_v2 PROD 20 Nov 2026.xlsx` (chủ vault đã gửi VTB; "v4.1" = uCRM v5). Chủ vault xác nhận v4 có thể giữ trong thời gian dài.

| Phát hiện | Hệ quả |
|---|---|
| Mọi rule PROD có Source = **UCRM_App_PROD 172.31.185.80 và 172.31.185.81** (outbound tới API, KeyCloak / IAM, Proxy, SAM, mail VTB 192.168.x; Qualtrics) | **App02 = 172.31.185.81 đã có trong yêu cầu gửi VTB.** Dựng App02 tại Duy Tân với IP này thì không cần xin rule mới. Chuyển App sang PVB thì phải xin lại toàn bộ |
| Không có rule nào trỏ tới DB v5 | Vị trí các node DB **không ảnh hưởng firewall VTB**, chỉ ảnh hưởng độ trễ App↔DB |
| App gọi DB nội bộ tại Duy Tân: MID-DB VIP 172.31.90.95, RepDB .90.98, Report-DB .90.77 (SQL 1433); và FSG2 reverse proxy 10.189.184.50 (HCM) | App phải ở cùng site với các DB nghiệp vụ VTB, tức **Duy Tân** |
| **v4 giữ lâu dài** | Không thu hồi được khoảng 3.4 TB của v4, nên **giai đoạn 2 ở §8.4 hoãn vô thời hạn**. Kiến trúc giai đoạn 1 phải là **trạng thái ổn định** |

#### Mô hình E' (khuyến nghị cuối): App và primary ở Duy Tân, 2 replica ở PVB

> **Sửa 2026-11-24 (chủ vault): dự án chỉ gồm 2 site Duy Tân và PVB, không dùng VDC.**
> - Bỏ etcd witness tại VDC. etcd chạy trên **DB01 + App02 (Duy Tân, 2 host khác nhau) và DB02 (PVB)**, không cần VM mới.
> - Đứt kênh: Duy Tân giữ 2/3 nên primary không bị demote.
> - Host DB01 hỏng: App02 + DB02 đủ quorum, Patroni promote DB02.
> - Mất cả Duy Tân: PVB chỉ có 1/3, không tự promote, phải DR thủ công. Chấp nhận được, vì khi đó dịch vụ đã dừng (PCCE3 và VTB đều vào ở Duy Tân).
> - Bảng bên dưới giữ dòng VDC chỉ để tham chiếu lịch sử, **không áp dụng**.
>
> Lưu ý mạng: đường IPsec hiện có giữa 2 site HN đi qua router hub tại HCM (x06). Đây chỉ là đường mạng, không đặt máy ở VDC.
| Site | Node | IP | Vai trò |
|---|---|---|---|
| Duy Tân | App01 (có sẵn) | 172.31.185.80 | Active |
| Duy Tân | **App02 (mới, khoảng 8 GB RAM / 60 GB)** | **172.31.185.81** (đã nằm trong yêu cầu FW VTB) | Active-active, keepalived / LB |
| Duy Tân | DB01 (có sẵn, thin) | 172.31.90.101 | **Primary** + etcd-1 + HAProxy (hoặc HAProxy trên App) |
| PVB | **DB02 (mới, thin, LUN02)** | 172.31.196.x (đề xuất) | Replica async + etcd-2; ứng viên failover |
| PVB | **DB03 (mới, thin, LUN02)** | 172.31.196.x | Replica async, **không tham gia etcd**, `nofailover` (DR / báo cáo) |
| VDC | **etcd witness** (2 GB RAM / 20 GB) | 10.169.x | etcd-3. Đứt kênh Duy Tân ↔ PVB thì Duy Tân + VDC giữ quorum, primary không bị demote |

- **Tài nguyên Duy Tân:** chỉ thêm App02 (60 GB). **Không thêm DB.** Nhưng DB01 (thin) sẽ tự lớn theo dữ liệu, khoảng 450 GiB lúc nhận v4 rồi khoảng +45 GB/tháng, trên SAN Duy Tân (Cust_SVR.01 còn 2.16 TB, đang 86%). **Bắt buộc dọn chỗ ở Duy Tân bằng tài nguyên sẵn có:** MidDB v4 đang tắt (300 GB), UAT v4 nếu không còn dùng (khoảng 0.33 TB), snapshot / file mồ côi. Kèm alarm.
- **Tài nguyên PVB:** 2 × (8 vCPU / 16 GB / thin khoảng 0.5 TB ban đầu) = 32 GB RAM, khoảng 1 TB trên LUN02.
- **Kênh liên site:** chỉ để replication + etcd. **IPsec hiện có là đủ, không phụ thuộc Metro.** Đứt kênh thì dịch vụ vẫn chạy (chỉ tạm mất bản sao).
- **Khi host DB01 hỏng:** cần chọn 1 trong 2 cách:
  - (a) Patroni tự promote DB02 ở PVB trong khoảng 30 giây; dịch vụ chạy tiếp nhưng **chậm** (App↔DB qua IPsec khoảng 30–60 ms) cho tới khi switchover về lại. Metro (khoảng 1–3 ms) sẽ khắc phục chỗ chậm này nếu sau này thuê.
  - (b) **Bật vSphere HA cho A-App Cluster** để DB01 tự khởi động lại trên host khác ở Duy Tân (khoảng 2–5 phút), còn PVB chỉ làm DR thủ công.
  - **Khuyến nghị: bật cả hai** (vSphere HA là cấu hình, không phải nâng cấp). Patroni (a) là lớp bảo vệ thứ 2 khi DB01 không lên lại được.
- **Theo dõi:** nếu failover sang PVB xảy ra thường xuyên, hoặc chế độ chậm không chấp nhận được, thì đây là căn cứ để xin Metro sau này.

**So với D:** không đổi firewall VTB; không phụ thuộc Metro; không chuyển subnet; App vẫn ở cạnh PCCE3, các DB nghiệp vụ VTB và điểm vào của VTB.
