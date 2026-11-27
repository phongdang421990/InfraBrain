---
type: design
status: draft
updated: 2026-11-24
tags: [design, network, inter-dc, metronet, fhn01, fhn02, postgresql]
---
# Đánh giá kết nối Duy Tân (FHN01) ↔ Phạm Văn Bạch (FHN02) cho mô hình App–DB tách site

Liên quan: [[_VTB-CRMv4-DB]] · [[FHN01]] · [[FHN02]] · [[BaseBS-Infra-Master-Overview]] · [[VietinBank]] (có note "kiến trúc UCRM giữa PVB và Duy Tân") · [[HD-SAISON]]

## 1. Yêu cầu (nguồn: email "Hỗ trợ về việc kết nối giữa 2 site FPT Duy Tân - FPT Phạm Văn Bạch !", 18–23/11/2026, hộp thư dangtp@basebs.com, đọc ngày 2026-11-24)
- **Đề bài** (anh Phong, Head of Service Delivery, gửi FPT DC – anh Trí ngày 18/11):
  - Server A (Application .NET) đặt tại **DC Duy Tân, vị trí CGY-CG3-i5**.
  - Server B (Database PostgreSQL) đặt tại **DC Phạm Văn Bạch, vị trí PVB-DC-L06-M3**.
  - App truy vấn DB liên tục, cần đường truyền ổn định, độ trễ thấp, "tương đương LAN".
  - Đã hỏi FPT 6 điểm: giải pháp (L2 / L3 / MPLS / cross-connect), băng thông và độ trễ cam kết, dự phòng và SLA, chi phí, thời gian triển khai, thông tin BaseBS cần chuẩn bị (IP / VLAN / thiết bị / rack / port).
- **FPT trả lời** (anh Phong chuyển tiếp ngày 23/11 14:16). FPT **chỉ đưa ra giá, không đưa giải pháp**:
  - Kênh **100 Mbps** (port 1 Gbps): **16.000.000 VND/tháng + VAT**.
  - Phí triển khai **5.000.000 VND/lần + VAT**.
  - Chưa gồm chi phí vật tư và thiết bị đầu cuối.
  - Nâng cấp thêm 5 / 10 / 50 Mbps: +2.5 / +4 / +11 triệu VND/tháng + VAT.
  - Chưa có thông tin về độ trễ cam kết, SLA, kênh backup và thời gian triển khai.
- **Việc giao cho Đăng** (anh Phong, 23/11):
  1. Cùng anh QuangBA đánh giá tài nguyên hạ tầng.
  2. Đánh giá **băng thông 100M có đáp ứng được App–DB đặt ở 2 DC không**.
  3. Cân nhắc phương án **triển khai Standard (như hiện tại) trước, sau go-live mới chuyển sang HA**.
  4. Nếu cần thì mời họp với anh Phong, anh Thanh (đại diện dev) và anh QuangBA.
- **Anh Thanh (Director, 23/11):** hỏi chi phí MetroNet hiện đang thuê để nối 2 điểm trong cùng thành phố, vì "mình có rất nhiều kết nối như vậy để kết nối với khách hàng".
- Webex space **CCX-CCE / General** (16–24/11): **không có** nội dung về kết nối PVB ↔ Duy Tân (đã đọc toàn bộ lịch sử và tìm theo từ khóa).

## 2. Hiện trạng kết nối giữa 2 site
| Điểm | Hiện trạng | Nguồn |
|---|---|---|
| Đường trực tiếp FHN01 ↔ FHN02 | **Chưa có bằng chứng.** BaseBS tự khai với FPT: "giữa các DC chỉ có VPN site-to-site" | [2N] x21 + x06 |
| IPsec | Hub ở RNET-01 VDC (HCM): tunnel tới FHN1.R1 (103.35.64.45), FHN1.R2, FHN2.R1. **Chưa rõ có tunnel trực tiếp FHN1 ↔ FHN2 hay không.** Nếu chỉ có hub-spoke, traffic HN→HN sẽ phải vòng qua HCM | [1N] x06 CLI |
| Metro ở FHN01 | ExtSW Po24 MetroFPT (VLAN khách hàng 1009 / 1010 / 1018 / 1082 HDSS); VietinBank Metro VNPT (main) / FPT (backup) | [1N] x05 |
| Metro ở FHN02 | HDSS MetroFPT (main), MetroCMC (backup, VLAN 2544) | [1N] x05 |
| Đo từ máy của Đăng (qua VPN, interface "Ethernet 5"), 2026-11-24 | vCenter PVB 10.199.110.10: ping ~24 ms, TCP 443 OK. vCenter Duy Tân 10.179.110.10: ping ~30 ms, TCP 443 OK | Lệnh `Test-Connection`, `Test-NetConnection`. **Không phản ánh độ trễ giữa 2 site** |
| Hạ tầng tính toán | FHN01: ESXi 6.5, Unity300 (hỏng đĩa liên tục). FHN02: 3 host R650xs / R660xs, ESXi 7.0.3, Unity380 | [2N] |

## 3. Đánh giá kỹ thuật [SL: suy luận kỹ thuật, cần đo để xác nhận]
### 3.1 Độ trễ quan trọng hơn băng thông
- App .NET truy vấn DB "liên tục", tức là mỗi nghiệp vụ gồm nhiều lượt request/response nối tiếp nhau. **Thời gian phản hồi ≈ số lượt truy vấn × RTT.**
  - Ví dụ: 200 truy vấn × 0.3 ms (cùng LAN) ≈ 0.06 s, còn 200 × 2 ms (Metro nội thành) ≈ 0.4 s.
  - Nếu đi IPsec vòng qua HCM (khoảng 25–40 ms): 200 × 30 ms ≈ **6 s**. Không chấp nhận được.
- Metro nội thành Hà Nội (Duy Tân, Cầu Giấy ↔ Phạm Văn Bạch, cách khoảng vài km) thường có RTT 1–3 ms. Như vậy vẫn **chậm hơn LAN khoảng 5–10 lần** cho mỗi truy vấn. "Tương đương LAN" là kỳ vọng không thực tế. Cần dev đo số truy vấn trên mỗi giao dịch.
- **100 Mbps:** với OLTP thông thường (query/response vài KB), 100 Mbps thường dư. Băng thông chỉ thành điểm nghẽn khi: chạy báo cáo hoặc export lớn, load blob/file, đồng bộ hoặc ETL (ví dụ DWH), backup đi qua kênh, hoặc replication khi chuyển sang HA. **Cần số đo traffic App↔DB thực tế** (peak Mbps, pps) từ môi trường hiện có.

### 3.2 Rủi ro của kiến trúc tách App và DB sang 2 DC
- **Kênh đơn là SPOF.** Mất kênh thì toàn bộ ứng dụng ngừng, trong khi không có thêm DC nào dự phòng. Mức an toàn tối thiểu cần **2 kênh đi khác tuyến**, hoặc 1 kênh Metro cộng IPsec qua Internet làm đường dự phòng (có suy giảm). FPT chưa trả lời về backup và SLA.
- Chưa rõ vì sao phải tách App và DB ra 2 site. Nếu mục tiêu là HA/DR thì cách tách này **không đem lại HA**: mất site nào thì ứng dụng cũng chết.

### 3.3 Phương án đề xuất để thảo luận
| Phương án | Mô tả | Ưu | Nhược |
|---|---|---|---|
| **A. Đặt App và DB cùng site (khuyến nghị cho giai đoạn Standard)** | App và PostgreSQL cùng đặt ở FHN02 (ESXi 7.0.3, Unity380, tài nguyên mới hơn) hoặc cùng ở FHN01 | Độ trễ đúng chuẩn LAN, **không cần kênh mới**, không có SPOF đường truyền | FHN01 dùng ESXi 6.5 và Unity300 đang yếu, nên nghiêng về FHN02 (cần kiểm tra tài nguyên) |
| **B. A + DR / HA sau go-live** | Giai đoạn 2: PostgreSQL streaming replication (async) từ site chính sang site kia qua kênh 100M; App standby ở site kia | Đúng tinh thần "Std trước, HA sau"; kênh 100M có lý do sử dụng rõ ràng | Tốn chi phí kênh 16 triệu/tháng; cần thiết kế failover |
| C. Tách App (Duy Tân) và DB (PVB) qua Metro 100M | Đúng như đề bài | Dùng tài nguyên của cả 2 site | Độ trễ mỗi truy vấn cao hơn LAN; SPOF đường truyền; phụ thuộc kênh |
| D. Dùng đường IPsec hiện có | Không tốn kênh mới | Rẻ | Nếu vòng qua HCM thì RTT khoảng 30 ms+, **không phù hợp** cho App–DB |

### 3.4 Nếu chọn kênh Metro (phương án B hoặc C): thông tin BaseBS cần chuẩn bị cho FPT
- **Dạng kết nối:** đề xuất **L3 point-to-point** (/30 hoặc /31 giữa FW hoặc RNET của 2 site, định tuyến tĩnh hoặc BGP). **Tránh kéo dài L2/VLAN** giữa 2 DC (gom chung broadcast domain, rủi ro STP lan sang site kia).
- **Điểm kết cuối:** port còn trống trên ExtSW FHN01 (C3850-24T, đã có Po24 MetroFPT) và ExtSW FHN02 (C9300-24T). Nếu đi FortiGate thì cần interface hoặc VLAN riêng cùng policy. Cần kiểm tra port và SFP còn trống (loại 1G LX/SX).
- **Quy hoạch IP:** subnet transit mới, không trùng 10.179/16, 10.199/16, 172.31/16. Policy FW chỉ mở port PostgreSQL 5432 từ App tới DB (cùng port replication khi làm HA).
- **Hỏi lại FPT:** RTT và jitter cam kết, SLA uptime, phương án kênh thứ 2 khác tuyến cùng giá, thời gian triển khai, có thể cấp dưới dạng VLAN trên Metro FPT sẵn có không (2 site đều đã có MetroFPT).

## 3.5 Tài nguyên thực tế (live 2026-11-24)
**FHN01 Duy Tân** (vcsa.ccxbasebs.com 6.5, 9 host, 201 VM):
- A-App Cluster: **HA OFF, DRS OFF**; RAM 70% (còn khoảng 650 GB), storage 83%.
- Datastore dùng chung: **Cust_SVR.01 86% (còn 2.16 TB)**, **Cust_SAN.BK 91% (còn 4.39 TB)**, cả hai đều CRITICAL.
- Host .47 PCCE3-B lỗi quạt từ 12/2024.
- **Kết luận:** Duy Tân **không phải nơi tốt để đặt thêm workload production mới**. Đặt Server A (App) ở đây cũng có nghĩa là chạy trên cluster không có HA.

**FHN02 PVB** (vcsa.hn02basebs.com **7.0.3 b22837322**, 1 cluster AppSvrs, 3 host, 116 VM):
- **HA ON** (Host Monitoring bật, VM Monitoring tắt). Admission control giữ lại 35% CPU / 33% RAM. **DRS ON nhưng ở chế độ Manual** (1 đề xuất đang chờ, DRS score 87%). **EVC Disabled.**
- RAM **858 / 1,120 GB (77%)**, còn trống khoảng 291 GB. Từng host: .21 71% (HA primary), **.22 84%**, .23 67%. CPU chỉ 7%.
- Storage: **UnityHN02_LUN01 91% (còn 3.36 / 37.81 TB), có alarm**. UnityHN02_LUN02 44% (**còn 5.55 / 10 TB**). Local 3 × 318 GB, gần như trống.
- **N+1 RAM không đạt:** nếu mất 1 host, 2 host còn lại có khoảng 747 GB, trong khi RAM đang dùng là 858 GB. HA vẫn restart VM (vì admission control dựa trên reservation) nhưng sẽ bị overcommit, ballooning hoặc swap.

**So sánh 2 site để đặt workload mới**
| Tiêu chí | Duy Tân (FHN01) | PVB (FHN02) |
|---|---|---|
| vSphere / ESXi | 6.5 (EOL) | **7.0.3** |
| HA | **OFF** | **ON** |
| DRS | OFF | ON (Manual) |
| RAM còn trống | khoảng 650 GB (cluster A-App, 70%) | khoảng 291 GB (77%), không đạt N+1 |
| Storage còn trống trên LUN chung | Cust_SVR.01 2.16 TB (86%), Cust_SAN.BK 4.39 TB (91%) | **LUN02 5.55 TB (44%)**, LUN01 3.36 TB (91%) |
| Storage array | Unity300 (hỏng đĩa liên tục) | Unity380 |
| Lỗi phần cứng đang mở | Quạt host .47 PCCE3-B từ 12/2024 | Không có |

**Kết luận [SL]:**
- **PVB phù hợp hơn để đặt cả App và DB** (phương án A): có HA, phiên bản mới hơn, còn LUN02 trống.
- **Nhưng PVB thiếu RAM.** Trước khi đặt thêm workload cần biết sizing của App + DB (vCPU / RAM / disk). Nếu tổng vượt khoảng 100–150 GB RAM thì nên **nâng RAM cho 3 host hoặc thêm host thứ 4** để giữ được N+1.
- Duy Tân chỉ nên làm site DR hoặc standby (phương án B, giai đoạn HA), và **phải bật HA cho A-App Cluster** trước đã.

## 3.6 Phương án Đăng đề xuất (2026-11-24): giữ App + DB hiện có ở Duy Tân, dựng thêm 1 App (HA) + 2 node PostgreSQL (Patroni)
**Đầu vào:**
- IP DB: Đăng ban đầu ghi 10.169.110.10, sau đó **đính chính là `172.31.90.101`** (2026-11-24). Tin nhắn của Ngân về Patroni (CCX-CCE, 23/11) **đã nạp ngày 2026-11-24**: xem [[_VTB-CRMv4-DB]] (CRM v4 chạy Percona/Patroni rút gọn 3 VM, go-live 06/2026, PG02 172.31.90.32 tăng ~1.2–1.5 GiB/ngày). Tin nhắn gốc của anh Phong (SUPPORT-INFRA) vẫn chưa đọc được.
- **Hệ thống là VietinBank uCRM v5** ([[VietinBank]]). Đọc live trên vCenter Duy Tân 2026-11-24:

| VM | OS | vCPU | RAM (active) | Disk (đã dùng) | Port group | Host |
|---|---|---|---|---|---|---|
| `VTB_uCRMv5_DB01_172.31.90.101` (ucrmv5-db01) | Oracle Linux 7 | 8 | 16 GB (2.1 GB) | 600 GB (144 GB) | PCCE3-DB | 10.179.110.22 (A-App, **không HA**) |
| `VTB_uCRMv5_App01_172.31.185.80` (ucrmv5-app01, có 2 IP) | Oracle Linux 7 | 8 | 8 GB (0.4 GB) | 60 GB | PCCE3-uCRM | 10.179.110.21 (A-App, **không HA**) |

  - Tải hiện tại rất thấp: DB 43 MHz CPU, 2 GB active. Hệ thống mới hoặc chưa go-live.
  - Folder vCenter: `VTB uCRMv5`. VMware Tools 12389.
  - **Oracle Linux 7 đã hết hỗ trợ chính thức (12/2024).** Node mới nên dùng OL8/9, và PostgreSQL phải cùng major version.

**Đánh giá [SL]: khả thi, nhưng phải giải quyết 6 điều kiện:**
1. **Quorum DCS (etcd / Consul) cần 3 thành viên, đặt sao cho khi đứt kênh không bị split-brain.** Với 2 site: đặt 2 thành viên ở site chính và 1 ở site phụ. Khi đó mất site chính thì site phụ **không tự promote** (phải failover tay, đây là hành vi an toàn). Muốn tự failover qua site thì cần **witness ở site thứ 3** (ví dụ 1 VM etcd nhỏ ở VDC, đi qua IPsec hiện có; độ trễ khoảng 30 ms vẫn chấp nhận được nếu tinh chỉnh timeout).
2. **Primary phải ở cùng site với App đang active.** Nếu App active ở Duy Tân mà Primary ở PVB thì quay lại đúng vấn đề độ trễ cộng dồn qua mỗi truy vấn. Mô hình hợp lý: site chính có App-active, PG primary và PG sync standby (replication đồng bộ trong LAN); site phụ có App-standby và PG async replica.
3. **Replication giữa 2 site nên để async.** Nếu sync qua kênh Metro thì mỗi lần commit cộng thêm RTT; nếu qua IPsec vòng HCM thì cộng thêm khoảng 30 ms. Băng thông cần ≥ lưu lượng WAL lúc cao điểm (dùng số liệu disk growth Ngân đã gửi để ước lượng).
4. **Đưa DB hiện có vào Patroni cần downtime.** Patroni phải tự bootstrap hoặc quản lý cluster; DB standalone cần chuyển sang (pg_basebackup hoặc restore vào node Patroni rồi cutover). Phải đi qua change-request và có cửa sổ bảo trì.
5. **Cách App kết nối tới primary:** dùng HAProxy (health check REST API Patroni cổng 8008) hoặc VIP (vip-manager / keepalived). App HA cũng cần LB riêng. Đặt các PG node trên **host khác nhau** (anti-affinity). PVB có 3 host nên làm được, nhưng DRS đang ở chế độ Manual nên phải kiểm tra rule có được áp dụng không.
6. **Tài nguyên:**
   - Duy Tân: A-App Cluster **không có HA**, storage 86–91%. Không nên thêm node ở đây.
   - PVB: còn khoảng 291 GB RAM nhưng **không đạt N+1**. LUN02 còn 5.55 TB. Lưu ý 2 node PG nghĩa là gấp đôi dung lượng DB.
   - Ví dụ: 3 VM mới (App 8–16 GB, PG 2 × 32 GB) tổng khoảng 72–80 GB RAM thì vừa, nhưng làm PVB càng xa N+1.

**Cập nhật sau khi có sizing (2026-11-24):**
- **Tài nguyên ở PVB: đủ.** Nếu nhân bản theo sizing hiện tại: App-2 (8 vCPU / 8 GB / 60 GB) + 2 node PG (8 vCPU / 16 GB / 600 GB mỗi node) + etcd nhỏ, tổng khoảng **42–46 GB RAM** và **khoảng 1.3 TB disk** (thin; thực dùng hiện khoảng 150 GB mỗi node DB). PVB còn khoảng 291 GB RAM, LUN02 còn 5.55 TB, nên đủ. RAM tăng thêm khoảng 4% so với hiện trạng; N+1 vẫn chưa đạt, như trước.
- **Băng thông:** tải DB hiện rất thấp, nên kênh 100M đủ cho replication async. Cần đo lại khi go-live.
- **Điểm khó thật sự là network và bảo mật ngân hàng**, không phải tài nguyên:
  - VM của VietinBank nằm trong mạng riêng 172.31.0.0/16 (port group PCCE3-DB, PCCE3-uCRM ở Duy Tân). Đặt node ở PVB thì cần **subnet 172.31.x mới (L3) ở PVB**, route và FW giữa 2 site. Không nên kéo dài L2 VLAN 90 / 185 sang site khác.
  - VIP dạng keepalived không nhảy qua L3 giữa 2 site được, nên dùng **HAProxy cùng Patroni REST health check**, hoặc DNS / connection string nhiều host (libpq `target_session_attrs=read-write`).
  - Phải được **VietinBank phê duyệt** (thay đổi kiến trúc, vị trí lưu dữ liệu ở DC thứ 2, policy FW, quét bảo mật). Theo CLAUDE.md §4.4: chỉ làm trong phạm vi được giao.

**Topology đề xuất [SL]:**
- **PVB (site chính):** App-2 (active), PG-1 (primary), PG-2 (sync standby), etcd ×2, HAProxy/VIP.
- **Duy Tân:** App-1 hiện có (standby), DB hiện có chuyển thành PG-3 (async replica, `nofailover` hoặc priority thấp), etcd ×1.
- (Tùy chọn) witness etcd ở VDC nếu muốn tự failover sang Duy Tân.
- Giai đoạn chuyển tiếp: giữ nguyên App + DB ở Duy Tân đến khi cutover sang PVB.

## 3.7 Yêu cầu đã chốt (Đăng, 2026-11-24)
- **2 VM App chạy HA** (đã có App01 ở Duy Tân, thêm 1). **3 node DB Patroni** (đã có DB01 ở Duy Tân, thêm 2).
- **Site chính: Duy Tân.**
- Ứng dụng do BaseBS quản lý; Đăng xác nhận không cần thông báo VTB. Ghi chú: nếu DB chứa dữ liệu khách hàng của VTB, cần đối chiếu điều khoản hợp đồng về vị trí lưu bản sao ở DC thứ 2 (việc này thuộc anh Phong).

### Đặt node như thế nào khi site chính là Duy Tân [SL]
**Bố trí A, khuyến nghị: HA trong cùng site, DR ở PVB**
| Site | Node | Ghi chú |
|---|---|---|
| Duy Tân | App01 (có sẵn, host .21) + **App02 mới** | Active-active sau LB / VIP (cùng L2 PCCE3-uCRM). Đặt trên host khác .21 |
| Duy Tân | DB01 (có sẵn, host .22): **primary** | |
| Duy Tân | **DB02 mới: sync standby** | Đặt trên host khác (ví dụ .25 với **SvrApp.05-Local.01 còn 2.33 TB**), để không phụ thuộc chung vào Unity300 với DB01 |
| PVB | **DB03 mới: async replica** | UnityHN02_LUN02. Đặt `nofailover: true` hoặc priority thấp, promote tay khi DR |
| etcd | 3 thành viên chạy cùng 3 node DB: 2 ở Duy Tân, 1 ở PVB | Khi đứt kênh, Duy Tân vẫn giữ quorum nên primary không bị demote |

- Ưu: App↔DB và replication đồng bộ đều trong LAN; host chết thì Patroni tự failover DB01 sang DB02 trong khoảng 30 giây và App còn 1 node; có bản sao DR ở PVB.
- Nhược: mất cả site Duy Tân thì phải failover tay sang PVB (promote DB03, dựng hoặc bật App ở PVB). RPO bằng độ trễ async.
- Tài nguyên tăng thêm ở Duy Tân: App02 (8 vCPU / 8 GB / 60 GB) + DB02 (8 / 16 / 600 GB thin) = **24 GB RAM** (A-App còn khoảng 650 GB) và khoảng 660 GB disk (nên dùng local). Ở PVB: DB03 16 GB RAM + 600 GB trên LUN02.

**Bố trí B: 2 node mới đều đặt ở PVB (App02 + DB02 + DB03). Không khuyến nghị**
- Khi primary ở Duy Tân thì sync standby nằm ở PVB, nên **mỗi commit phải cộng RTT giữa 2 site**. Nếu để async thì failover có thể mất dữ liệu.
- App02 ở PVB truy vấn DB ở Duy Tân sẽ chậm, nên trên thực tế không chạy active-active được.
- **etcd sẽ có đa số ở PVB.** Khi kênh chập chờn, primary ở Duy Tân mất quorum nên **tự demote, làm site chính ngừng hoạt động**. Đây là lỗi thiết kế nghiêm trọng.

**Thành phần kèm theo (bố trí A)**
- App truy cập DB qua **HAProxy** (chạy trên mỗi App VM, health check `GET /primary` cổng 8008 của Patroni), hoặc dùng libpq multi-host với `target_session_attrs=read-write`.
- LB cho 2 App: keepalived VIP trên VLAN PCCE3-uCRM, hoặc dùng NLB đã có trong hệ VTB (cần xác minh).
- Port cần mở giữa Duy Tân và PVB (chỉ cho DB03): 5432 (replication), 2379 / 2380 (etcd), 8008 (Patroni REST). Ở PVB cần một **subnet 172.31.x mới** (L3) cùng route. **Có thể khởi động bằng đường IPsec hiện có** (async và etcd chịu được độ trễ khoảng 30–60 ms nếu chỉnh timeout); kênh Metro 100M là cải thiện về sau, không phải điều kiện tiên quyết.
- OS node mới: OL8/9; PostgreSQL cùng major version với DB01 (cần kiểm tra). Patroni + etcd 3.5.
- Khuyến nghị kèm theo: **bật vSphere HA cho A-App Cluster** (R-017), vì App và DB đang ở trên cluster này.

## 3.8 Ràng buộc mới (Đăng, 2026-11-24): Duy Tân không dựng thêm được DB; chỉ dùng SAN, không dùng local disk
Bố trí A ở mục 3.7 bị loại (DB02 không đặt ở Duy Tân được). **Hai node DB mới bắt buộc đặt ở PVB.** Vì vậy etcd có đa số ở PVB, và nếu không xử lý thì đứt kênh sẽ làm primary ở Duy Tân tự demote.

**Phương án C, khuyến nghị nếu giữ site chính ở Duy Tân: dùng witness etcd ở VDC**
| Site | Node | Vai trò |
|---|---|---|
| Duy Tân | App01 (có sẵn) + App02 (mới, 60 GB trên SAN Cust_SVR.01 nếu được; nếu không thì đặt ở PVB) | App active (cùng site với primary) |
| Duy Tân | DB01 (có sẵn) | **Primary** + etcd-1 |
| PVB | DB02, DB03 (mới, UnityHN02_LUN02) | Replica **async** (sync khi đã có kênh Metro độ trễ thấp) + etcd-2 trên DB02 |
| **VDC** | **etcd-3 witness** (VM 1–2 vCPU / 2 GB / 20 GB) | Phân xử quorum. VDC là hub IPsec, đã có tunnel tới cả FHN1 và FHN2 |

- Đứt kênh Duy Tân ↔ PVB: Duy Tân + VDC vẫn đủ quorum, primary giữ nguyên, PVB không promote. ✅
- Mất PVB: không ảnh hưởng. ✅
- Mất host DB01 hoặc mất site Duy Tân: PVB + VDC đủ quorum, **Patroni tự promote DB02** (giới hạn bằng `maximum_lag_on_failover` để tránh mất nhiều dữ liệu). Sau đó App ở Duy Tân truy vấn DB qua kênh liên site (chậm) cho tới khi chuyển App sang PVB hoặc failback. ⚠️
- Replication: **async** khi còn đi qua IPsec vòng HCM (mỗi commit đi sync sẽ cộng khoảng 30–60 ms). Khi có Metro (khoảng 1–3 ms) có thể bật `synchronous_mode` với 1 standby ở PVB.
- Port: Duy Tân ↔ PVB: 5432, 2379/2380, 8008. Duy Tân ↔ VDC và PVB ↔ VDC: 2379/2380 (etcd). Cần route 172.31.x mới ở PVB và etcd witness ở VDC qua IPsec.
- Tài nguyên: Duy Tân chỉ thêm App02 (8 GB RAM, 60 GB SAN) hoặc không thêm gì. PVB: 2 × (8 vCPU / 16 GB / 600 GB) = 32 GB RAM, 1.2 TB trên LUN02 (còn 5.55 TB). VDC: 2 GB RAM.

**Phương án D, tốt hơn về kỹ thuật: chuyển site chính DB sang PVB**
- PVB: DB02 primary + DB03 sync standby (LAN) + App02 active. Duy Tân: DB01 thành async replica cho DR, App01 standby.
- Có HA trong cùng site cho DB, không cần witness. PVB có vSphere HA, ESXi 7.0.3, Unity380; Duy Tân đang ESXi 6.5, không HA, Unity300 hỏng đĩa, SAN 86–91%.
- Nhược: đi ngược mong muốn "site chính ở Duy Tân"; App phải active ở PVB.

**Gợi ý:** giai đoạn đầu chạy **C** (ít thay đổi, giữ App/DB01 ở Duy Tân). Lập lộ trình chuyển sang **D** (switchover có kế hoạch bằng `patronictl switchover`, gần như không mất dữ liệu) khi đã có kênh Metro hoặc khi hạ tầng Duy Tân cần refresh.

## 4. Việc cần làm để chốt (read-only trước)
1. **Đo độ trễ thực tế giữa 2 site:** từ 1 VM ở Duy Tân chạy ping / traceroute tới 1 IP ở PVB (ví dụ 10.199.110.10), xem đường đi có vòng qua VDC không. Trên FHN1.R1 / FHN2.R1: `show crypto session`, `show ip route 10.199.0.0` (Đăng tự đăng nhập).
2. **Tài nguyên** (câu hỏi gửi anh QuangBA): đọc vCenter 10.179.110.10 và 10.199.110.10 ở chế độ read-only (free CPU / RAM / datastore, N+1), giống cách đã làm cho VDC.
3. **Hồ sơ traffic từ dev (anh Thanh):** số truy vấn trên mỗi giao dịch, peak TPS, kích thước DB, có báo cáo hoặc ETL không, có cần HA không và RPO / RTO.
4. **Chi phí MetroNet hiện có** (câu hỏi của anh Thanh): không có trong vault. Cần lấy hợp đồng hoặc hóa đơn các kênh Metro hiện tại (TPBank / Vinacis / MBAL / HDSS / VietinBank...) để so với báo giá 16 triệu/tháng cho 100M.
5. Họp với anh Phong, anh Thanh và anh QuangBA để chọn phương án A/B/C.

## 5. Brief phương án trên Claude Docs (2026-11-24, Claude chat)
- Brief: https://claude.ai/artifact/641DB2hBczxN1ct7YZQAhg ("Brief: Phương án HA 2 site cho VTB uCRM v5").
- ⚠️ Brief được viết **trước khi** Đăng chốt "site chính = Duy Tân" (§3.7). Brief giả định **primary ở PVB**, nên khuyến nghị của brief (PA2: primary cluster 2 node + 3 etcd ở PVB, standby cluster DB01 ở Duy Tân, DR = `patronictl promote-cluster`) tương ứng với **phương án D** ở §3.8. PA1 của brief (1 cluster, etcd 2 PVB + 1 Duy Tân, primary PVB) cũng là primary ở PVB. Brief **chưa có phương án C** (witness etcd ở VDC). Cần cập nhật brief nếu giữ site chính ở Duy Tân.
- Điểm của brief vẫn dùng được cho mọi phương án:
  - Sizing tham chiếu từ CRM v4 ([[_VTB-CRMv4-DB]]): nếu v5 tăng như v4 (~1.2–1.5 GiB/ngày) thì 600 GB/node không đủ cho 12 tháng → ~1 TB/node; tách disk data/WAL khỏi `/`.
  - DB01 chạy OL7 (glibc 2.17), node mới OL8/9 (glibc 2.28) → collation khác; physical replication trộn OS có nguy cơ hỏng index text. Dựng DB01 lại cùng OS, hoặc chuyển dữ liệu bằng dump/restore / logical replication rồi REINDEX.
  - `max_slot_wal_keep_size` cho replication slot liên site.
  - Hỏi: v5 đã go-live chưa? Nếu chưa → dựng HA trước go-live, không cần downtime ([[open-questions]] #20).

## 6. Cập nhật mạng và quyết định (2026-11-24 tối, Claude chat)
- **Sheet tổng hợp** (phương án, tài nguyên, tăng trưởng DB, rủi ro, quy hoạch IP, luồng FW, việc cần chốt): https://claude.ai/artifact/EqgKL7TgkeRU8bFXoXbkbW. Phương án chọn: **PA-A** (App01 + App02 ở Duy Tân, DB01 primary Duy Tân, DB02 + DB03 ở PVB, etcd 2 Duy Tân + 1 PVB).
- **Sửa VLAN:** VTB ở Duy Tân là **VLAN 290 (PCCE3-DB 172.31.90.0/24)** và **VLAN 285 (PCCE3-uCRM 172.31.185.0/24)**, gateway trên FortiGate External-Primary. Các chỗ trước ghi "VLAN 90/185" là nhầm sang dải BaseBS 10.179.x.
- **PVB:** subnet mới **VLAN 291 – 172.31.91.0/24**, gateway 172.31.91.1 trên FHN02-FW01; DB02 .102, DB03 .103.
- **Transit Metro:** 10.179.254.0/30 trên routed port ExtSW (FHN1 Gi1/0/20 .1 ↔ FHN2 Gi1/0/21 .2); route: FortiGate → ExtSW (.20.234) → transit. ExtSW PVB không có default route nên cần route riêng 172.31.91.0/24 → 10.199.20.123. Chi tiết: [[FHN02]] mục Network live.
- **Quyết định Đăng:** DB01 **giữ nguyên** (không dựng lại); OS node mới chốt theo collation của DB01 (`en_US.UTF-8` → OL7 như DB01; `C` → OL8/9). Disk DB **giữ 600 GB/node**. Tốc độ tăng dùng để sizing: **1.70 GiB/ngày** (trung bình growth trend 35 ngày của v4, Đăng chốt) → chạm 80% khoảng 06/2027, đầy khoảng 08/2027; mở rộng online trước 05/2027. Dùng dải transit mới, **không dùng lại 10.179.255.4/30**.
- **Phát hiện:** cả 2 cụm FortiGate tắt session pickup (R-023); FortiGate FHN1 chưa reboot từ 12/2018 (R-024); FHN1 và FHN2 cùng nằm trong segment Metro FPT của HDSS 192.168.100.48/29 → có thể đo RTT thật giữa 2 site (cần Đăng đồng ý).
