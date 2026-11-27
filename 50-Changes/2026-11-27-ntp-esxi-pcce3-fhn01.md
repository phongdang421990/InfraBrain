---
type: change
status: draft
risk: TB   # nâng Cao nếu 0c thấy VM PCCE đồng bộ giờ theo host
window: "Khung ít cuộc gọi nhất đã thống nhất với VietinBank; không trùng go-live / cutover uCRM v5; giờ cụ thể Đăng chốt"
systems: ["[[FHN01]]", "ESXi 10.179.110.47 (PCCE3-B)", "ESXi 10.179.110.45 (PCCE3-A)", "vCenter 10.179.110.10"]
customer: "[[VietinBank]]"
updated: 2026-11-27
tags: [change, ntp, esxi, vsphere, fhn01, pcce3, vietinbank, R-014]
---
# CR: Chỉnh giờ và bật NTP cho 2 host ESXi PCCE3 VietinBank (10.179.110.47 / .45), FHN01

> **Bản nháp, chưa thực thi gì.** `infra-sentinel` soạn ngày 2026-11-27, không truy cập hệ thống nào khi soạn. Chỉ thực hiện khi Đăng gõ "DUYỆT" cho đúng CR này (duyệt CR SMB không áp dụng ở đây). Phần tầng ứng dụng PCCE3 (checklist mục B / C / D) do `cc-echo` viết.
> Nguồn chính: [[2026-11-25-vsphere-health-FSG-FHN]] (gọi tắt **HC25**), đọc live vSphere UI ngày 25/11; lệch giờ đo bằng cách so "Date & Time" của host với đồng hồ trình duyệt, sai số ±10 s. Nhãn: **[SL]** = suy luận; **[cần xác minh]** = chưa có bằng chứng.

## Mục tiêu và lý do
Hiện trạng, **đã xác minh** live 25/11 (HC25 §2.2, §3.4), xếp theo thứ tự thực thi:

| Host | Model / ESXi | VM | NTP client (firewall) / ntpd | Server | Lệch (host − chuẩn) |
|---|---|---|---|---|---|
| 10.179.110.47 (PCCE3-B) | BE7H-M5, Gold 6132, 6.5.0 b8294253, local disk | 7 | Enabled / Stopped | 10.179.120.20 | ≈ −19 phút |
| 10.179.110.45 (PCCE3-A) | BE7H-M5, Gold 6132, 6.5.0 b8294253, local disk | 8 | Enabled / Stopped | 10.179.120.20 | ≈ −25 phút |

- Hai phía A / B lệch nhau ≈ 6 phút và cùng chậm 19–25 phút so với giờ chuẩn (HC25 §2.2). .47 có alarm "Host hardware fan status" Critical từ 19/12/2024, đã ack 13/06/2025 (HC25 §3.4; [[risk-register]] R-018).
- Hệ quả ([[risk-register]] R-014, mức Rất cao; HC25 §2.2): VMware Tools đồng bộ giờ một lần cho guest khi tạo / revert snapshot, vMotion, resume, khi Tools khởi động, nên guest PCCE có thể nhảy giờ. Rủi ro cao với CUCM / PCCE, TLS / SIP, Kerberos, CDR và ghi âm; log và timeline RCA sai.
- Server 10.179.120.20 (AD / DNS CN247, [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục D) đang giữ 5 host A-App FHN01 lệch ≈ 0 (HC25 §3.4; [[FHN01]]) → nguồn đã chứng minh, **giữ nguyên server**. Firewall NTP Client đã Enabled; chỉ thiếu ntpd Running và startup policy.
- Mục tiêu: 2 host lệch ≤ 2 s so với UTC; ntpd Running; policy "Start and stop with host"; server 10.179.120.20.
- [[VietinBank]] (mục Lưu ý) đã chốt hướng: xử lý qua `change-request`, phối hợp `cc-echo`.

## Phạm vi ảnh hưởng
- Hệ thống: [[FHN01]]; vCenter vcsa.ccxbasebs.com 10.179.110.10 (6.5.0 b24045034), datacenter FDCHN, cluster "PCCE Cluster03". HA / DRS của cluster này chưa ghi nhận → 0a.
- Khách hàng: [[VietinBank]], PCCE3 PROD (side A trên .45, side B trên .47). Phạm vi thao tác: **chỉ cấu hình giờ / NTP của 2 host ESXi**; không đụng VM hay ứng dụng VietinBank, trừ ứng phó theo checklist cc-echo mục D.
- [SL] 2 host chạy 15 VM (8 + 7) trong khi [[FHN01]] ghi quy mô 21 VM PCCE3 → khoảng 6 VM PCCE3 nằm trên host khác, ngoài phạm vi CR này; 0c liệt kê.
- Gián đoạn: **Không** (dự kiến). Không maintenance mode, không reboot, không vMotion (PCCE3 chạy local disk nên cũng không vMotion được). Thời lượng: khoảng 60–90 phút thực thi, gồm checklist cc-echo và 15–30 phút quan sát giữa 2 host; cộng khoảng 30 phút pre-check nhanh ngay trước, tổng 1,5–2 giờ (cc-echo mục E).
- **Mức rủi ro đề xuất: TB**, nâng **Cao** nếu 0c thấy VM PCCE đồng bộ giờ theo host. Lý do: PROD contact center của ngân hàng; nhưng chỉ đổi tầng host, guest không đổi giờ theo host trừ khi VMware Tools đồng bộ (0c, 0e); bước nhảy nhỏ (19–25 phút, nhảy tiến); làm từng phía, side B trước, có quan sát.
- Rủi ro cụ thể và cách chặn:
  - Guest PCCE nhảy giờ do "Synchronize guest time with host", hoặc do snapshot / Tools restart trong cửa sổ → 0c, 0e, checklist cc-echo mục B.
  - VCSA ở chế độ giờ Host và nằm trên .45 / .47 → 0d.
  - [SL] Nhảy giờ có thể làm host báo Not responding thoáng qua → điều kiện dừng.
  - [SL] Trong lúc quan sát, giờ host A / B tạm chênh ≈ 25 phút (chỉ tầng host; guest không đổi nếu 0c, 0e đạt).
  - Alarm quạt .47 (R-018) không xử lý trong CR này; ghi baseline ở 0a để không nhầm với alarm mới.
- Thông báo cho: VietinBank theo hợp đồng ([[VietinBank]] mục SLA / liên hệ còn trống → Đăng xác nhận đầu mối và thời hạn báo trước; ghi vào [[open-questions]]); nội bộ: người trực PCCE, team uCRM v5.
- Cửa sổ: khung ít cuộc gọi nhất đã thống nhất với VietinBank; **không trùng go-live / cutover uCRM v5 PROD** (email nội bộ của phongth ngày 23/11, thread "VTB-UCRM PRO V5": uCRM v5 đang chuẩn bị go-live, khi chuyển đổi cần theo dõi trên App / DB).

## Điều kiện tiên quyết
- [ ] Pre-check 0a, 0c–0f và checklist cc-echo mục B xong, ghi vào "Kết quả thực tế", mọi tiêu chí đạt
- [ ] Cửa sổ đã thống nhất với VietinBank, không trùng go-live / cutover uCRM v5
- [ ] Đã thông báo VietinBank theo hợp đồng; đầu mối: ____ (Đăng xác nhận)
- [ ] Người trực PCCE standby: ____ ; cc-echo sẵn sàng chạy mục C, D
- [ ] PowerCLI kết nối được 10.179.110.10, Đăng tự đăng nhập [cần xác minh: HC25 chỉ dùng UI]. Không dùng được → làm bằng UI và ghi "chưa đo được ngưỡng 2 s" (UI chỉ chính xác ±10 s)
- [ ] (Tùy chọn) Backup cấu hình host: `Get-VMHostFirmware -VMHost $h -BackupConfiguration -DestinationPath <thư mục>`. Chỉ để lưu, không dùng làm rollback (restore bundle cần maintenance mode và reboot)
- [ ] **Không** tạo snapshot VM PCCE: không cần (thay đổi ở tầng host) và không nên (tạo snapshot gây đồng bộ giờ một lần cho guest)

## Đánh giá ảnh hưởng tầng PCCE3 (cc-echo)
**Phạm vi:** tầng ứng dụng PCCE3 [[VietinBank]] trên PCCE Cluster03. Thứ tự: 10.179.110.47 (PCCE3-B) trước, 10.179.110.45 (PCCE3-A) sau. Lệnh và rollback tầng ESXi thuộc phần `infra-sentinel`. Người soạn: `cc-echo`, 2026-11-27.

**Nhãn:** [đã xác minh] = có trong vault (kèm nguồn) · [SL] = suy luận · [cần xác minh] = lệnh hoặc giao diện chưa chắc đúng tên trên PCCE 12.x. Kiến thức chung về Microsoft / Cisco / VMware không gắn nhãn.

**Nguồn:** [[2026-11-25-vsphere-health-FSG-FHN]] (gọi tắt "health 2026-11-25") §2.2, §3.4 · [[FHN01]] · [[VietinBank]] · [[risk-register]] R-014, R-018, R-031 · email phongth (BaseBS) 2026-11-23 về uCRM v5.

### A. Vì sao đồng bộ giờ quan trọng với PCCE3

Call flow và vùng ảnh hưởng của change (chỉ các VM chạy trên .45 / .47):

```
Carrier/SIP -> VGW/CUBE -> CVP -> Router/Logger -> PG/CG -> CUCM -> Finesse/Agent -> uCRM v5
               (ISR vật lý)[------- VM PCCE3 trên .45/.47 (pre-check #1) -------]    (A-App)
```

- **Windows CCE** (Rogger, PG / CG, AW-HDS-DDS, CVP, ECE nếu có): giờ đi theo domain (member → DC → PDC Emulator → nguồn NTP ngoài). Kerberos mặc định chỉ chấp nhận lệch **tối đa 5 phút**. Quá ngưỡng thì xác thực giữa các máy hỏng: service logon, SQL Windows auth (Logger → HDS replication, AW), CCE Admin, Diagnostic Framework.
- **VOS** (CUCM, Finesse, CUIC / LiveData / IdS, VVB): dùng NTP. Publisher trỏ NTP ngoài (bắt buộc khi chạy trên VM); subscriber và node phụ lấy giờ từ publisher. DB replication (Informix) giữa các node và kiểm tra hiệu lực cert (TLS Finesse ↔ CUCM / CUIC, SAML nếu dùng IdS) đều cần giờ khớp. Nếu VMware Tools kéo một VM VOS về giờ host (lệch 19–25 phút, vượt ngưỡng khoảng 1000 s ≈ 17 phút), ntpd trong VOS có thể không tự sửa lại được [cần xác minh hành vi trên VOS 12.x].
- **Router / Logger side A–B:** chạy duplex qua MDS, xử lý cùng một chuỗi sự kiện và ghi cùng dữ liệu vào Logger A / B. Nếu giờ hệ thống hai side lệch nhau, log và timestamp không khớp, timeline RCA sai [SL cho phần ảnh hưởng tới dữ liệu].
- **HDS / CUIC:** dữ liệu lịch sử ghi theo interval 15 / 30 phút; DateTime theo giờ central controller (kèm cột TimeZone). Giờ nhảy tiến thì hụt interval; nhảy lùi thì trùng hoặc mất bản ghi interval, CUIC sai số [SL]. Change này không đổi timezone của guest.
- **Calabrio / ghi âm, WFM** (VTB có Calabrio, Recording, WFM [đã xác minh [[VietinBank]]]): bản ghi được gắn thời gian rồi ghép với sự kiện CTI / CDR. Lệch giờ làm tìm và ghép bản ghi sai, khó tra soát khiếu nại; với ngân hàng đây là điểm nhạy cảm [SL].
- **CTI tới uCRM:** screen pop chạy theo sự kiện realtime nên ít phụ thuộc giờ; lịch sử cuộc gọi, thời lượng và token đăng nhập (nếu có SSO) thì phụ thuộc giờ server [SL]. uCRM v5 PROD tích hợp với PCCE3 (CTI, CUCM, Finesse) và sắp go-live [đã xác minh: email 2026-11-23].

**Đánh giá ảnh hưởng của change này**
- Giờ host chỉ tác động tới guest qua VMware Tools theo hai đường: (1) đồng bộ định kỳ khi bật "Synchronize guest time with host"; (2) đồng bộ một lần khi Tools khởi động (mỗi lần guest boot), vMotion, tạo / revert snapshot, resume. Bỏ tick chỉ tắt được (1); muốn tắt (2) phải đặt advanced setting `time.synchronize.*` (VMware KB 1189) [cần xác minh]. Ngoài hai đường này, đổi giờ host không làm guest đang chạy đổi giờ.
- **Không ảnh hưởng** (kỳ vọng) nếu mọi VM trên .45 / .47 tắt Sync và giờ guest đúng so với 10.179.120.20. Change còn **gỡ một rủi ro đang có**: hiện nay, mỗi lần backup bằng snapshot, reboot hay nâng cấp Tools, guest có thể bị kéo về giờ host (chậm 19–25 phút) rồi phải chờ w32time / NTP kéo lại [SL].
- **Có ảnh hưởng** nếu có guest đang đi theo host (lệch ≈ −19 phút trên .47, ≈ −25 phút trên .45). Khi sửa host, guest đó nhảy tiến 19–25 phút: lỗi Kerberos, hụt interval, ghi âm sai giờ → **DỪNG, thiết kế lại** (xem mục B).
- Quãng giữa hai host: B đã đúng giờ, A còn chậm khoảng 25 phút. Nếu có guest đi theo host, độ lệch A–B tăng từ khoảng 6 phút [đã xác minh health 2026-11-25 §2.2] lên khoảng 25 phút. Vì vậy phải chứng minh "không guest nào đi theo host" trước khi bắt đầu, và không chờ quá 30 phút giữa hai host [SL].
- Ngoài phạm vi nhưng gấp: `VTB_uCRMv5_DB01` 172.31.90.101 chạy trên host .22 [đã xác minh [[VietinBank]]]. Host .22 đang lệch ≈ +7 giờ 58 phút và NTP trỏ nhầm 10.189.120.20 [đã xác minh health 2026-11-25 §3.4]. Một lần snapshot / backup DB01 có thể kéo guest tiến khoảng 8 giờ [SL] → nên sửa NTP .22 (CR riêng) trước go-live uCRM v5.

### B. Pre-check tầng ứng dụng (read-only)

Chạy đầy đủ trước 1 ngày; chạy lại #2–#13 và #15–#16 ngay trước bước 1 của CR. Đăng và kỹ sư PCCE tự đăng nhập; chỉ dùng lệnh đọc; dán output vào phần Pre-check của CR.

| # | Kiểm tra | Lệnh / nơi xem | Kết quả mong đợi | Nếu khác → làm gì |
|---|---|---|---|---|
| 1 | Danh sách VM trên .45 / .47, vai trò, side | vCenter → PCCE Cluster03 → host → VMs; PowerCLI P1 (dưới bảng) | .45: 8 VM, .47: 7 VM [đã xác minh health 2026-11-25 §3.4]. Mỗi VM được gán vai trò (Rogger, PG / CG, AW-HDS-DDS, CVP, CUCM, Finesse, CUIC / LiveData / IdS, VVB…) và side. Vault mới biết tên `PCCE3-ROGGER-A` [đã xác minh [[FHN01]]] | Số VM khác, hoặc có VM chưa rõ vai trò → hỏi Đăng trước khi làm. Vault ghi 21 VM PCCE3, tức khoảng 6 VM nằm ở host khác [SL]: tìm host của chúng; nếu ở .22 / .53 (đang lệch giờ) → ghi vào R-014 |
| 2 | "Synchronize guest time with host" | VM → Edit Settings → VM Options → VMware Tools; P1 cột `SyncTimeWithHost` | `False` cho mọi VM trên .45 / .47 (kiểm cả các VM PCCE3 ở host khác) | **DỪNG**. Nếu giờ guest vẫn đúng thì rủi ro thấp [SL], nhưng Đăng phải chọn: tắt Sync trước (bổ sung CR, DUYỆT lại) hoặc ghi rõ việc chấp nhận rủi ro vào CR |
| 3 | Giờ guest Windows so với 10.179.120.20 | `w32tm /query /status`; `w32tm /query /source`; `w32tm /stripchart /computer:10.179.120.20 /samples:3 /dataonly` | Source là DC của domain PCCE3 (máy không join domain: nguồn NTP đã cấu hình), không phải `Local CMOS Clock` / `Free-running System Clock`; offset ≤ 2 s | ≈ −19 phút (.47) / ≈ −25 phút (.45), hoặc ≥ 1 phút → **DỪNG**. Từ 2 s đến 1 phút → ghi nhận, báo Đăng. Stripchart timeout (FortiGate có thể chặn UDP 123 từ 172.31.x [SL]) → đo so với PDC (#5) rồi đo PDC với 10.179.120.20; không mở rule trong CR này |
| 4 | Giờ guest VOS | `utils ntp status`; `utils ntp server list` [cần xác minh trên subscriber]; `show status` | "synchronised", offset vài ms; node phụ trỏ về publisher; publisher khớp 10.179.120.20 trong 2 s (trực tiếp hoặc qua nguồn của nó) | "unsynchronised" hoặc lệch ≥ 1 phút → **DỪNG** |
| 5 | PDC của domain PCCE3 và nguồn giờ của nó | `netdom query fsmo` hoặc `nltest /dsgetdc:<domain> /pdc`; trên PDC: `w32tm /query /source`, `w32tm /query /configuration`, stripchart như #3; `w32tm /monitor` | PDC Type NTP, nguồn là 10.179.120.20 hoặc nguồn khớp trong 2 s; biết PDC chạy trên host nào (DNS PROD 172.31.253.51 [đã xác minh [[VietinBank]]] có thể là DC [cần xác minh]) | PDC dùng Local CMOS / Free-running, hoặc PDC là VM trên .45 / .47 đi theo host → **DỪNG** (cả domain đang theo host) |
| 6 | Dịch vụ ICM | Unified CCE Service Control trên từng VM ICM; Diagnostic Framework Portico `https://<host>:7890/icm-dp/rest/DiagnosticPortal` [cần xác minh]; Event Viewer 24 h gần nhất | Mọi service Cisco ICM Running; không có lỗi lặp lại (Kerberos `KRB_AP_ERR_SKEW`, Time-Service) | **DỪNG**, xử lý riêng |
| 7 | Router A / B, Logger A / B | `rttest /cust <inst>`, chỉ dùng lệnh `status` [cần xác minh]; hoặc Portico | Hai Router synchronized (duplex), hai Logger đều kết nối | Một side isolated / simplex → **DỪNG** |
| 8 | PG / CG: side active | `opctest /cust <inst>`, chỉ dùng lệnh `status` [cần xác minh]; hoặc Portico (PIM / CTI Server Active, Idle) | Mỗi PG / CG có 1 side Active, side kia Idle; ghi lại side đang active để so sau change | Một side down → **DỪNG** |
| 9 | Finesse | `utils service list` (Cisco Finesse Tomcat, Notification Service STARTED) [cần xác minh tên]; `https://<finesse>:8445/finesse/api/SystemInfo` hoặc cfadmin [cần xác minh cổng] | Hai node IN_SERVICE | **DỪNG** |
| 10 | CUCM | Trên publisher: `utils dbreplication runtimestate`; `utils service list` (Cisco CallManager, Cisco CTIManager); `show status` | Mọi node `(2) Setup Completed`; service STARTED | **DỪNG** |
| 11 | CVP, VGW | CCE Admin Inventory hoặc OAMP [cần xác minh]; service Windows CVP Call Server / VXML Server [cần xác minh tên]; trên VGW: `show call active voice brief`, `show clock`, `show ntp associations` | CVP Up; VGW có cuộc gọi khi có traffic; giờ VGW đúng (VGW là ISR vật lý [đã xác minh [[FHN01]]], không thuộc change, chỉ dùng để đối chiếu log) | CVP lỗi → **DỪNG**; giờ VGW sai → ghi nhận, xử lý ở CR riêng |
| 12 | CUIC / LiveData / IdS | Đăng nhập CUIC, chạy một report realtime; `utils service list`; `show live-data failover` [cần xác minh] | Report realtime cập nhật, LiveData chạy | **DỪNG** (mất công cụ để verify) |
| 13 | Alert CCE Admin, phần cứng | `https://<AW>/cceadmin` → Inventory / Alerts [cần xác minh]; alarm vCenter của .45 / .47 | Không có alert mới; chỉ còn alarm quạt .47 đã biết (R-018) [đã xác minh] | Alert mới chưa rõ nguyên nhân → **DỪNG** |
| 14 | Disk `PCCE3-ROGGER-A` | `Get-Volume` trên VM | E: khoảng 90% [đã xác minh [[FHN01]], R-031], không tăng bất thường | ≥ 95% → **DỪNG**, xử lý R-031 trước |
| 15 | Tải, agent | Report LiveData Agent / Agent Team hoặc Finesse supervisor [cần xác minh tên report]; CUIC lượng gọi theo giờ | Ghi lại số agent login và số cuộc gọi đang xử lý; đúng khung ít tải đã thống nhất với VTB | Cao điểm, đang có sự cố hoặc ticket mở → **DỪNG**, dời lịch |
| 16 | Snapshot / backup | Lịch job backup dạng snapshot cho VM PCCE3 (vault chưa ghi công cụ backup [cần xác minh]); vCenter Scheduled Tasks / Recent Tasks | Không job snapshot nào chạy trên VM .45 / .47 trong cửa sổ | Có → dời cửa sổ (không sửa job trong CR này) |
| 17 | Cuộc gọi test (nếu VTB cho phép) | Gọi số test → IVR → queue → agent test → trả lời → gác máy; không dùng dữ liệu khách hàng thật | Thông suốt; Finesse đổi state; uCRM screen pop lên; có bản ghi âm; ghi lại giờ gọi để đối chiếu TCD / CUIC / Calabrio | Lỗi → **DỪNG** (lỗi có sẵn, không phải do change) |

```powershell
# P1: chỉ đọc. Đăng tự Connect-VIServer vcsa.ccxbasebs.com trước. Tên host trong vCenter là IP hay FQDN: [cần xác minh]
$vms = Get-VMHost -Name 10.179.110.45, 10.179.110.47 | Get-VM
$vms | Select-Object @{N='Host';E={$_.VMHost.Name}}, Name, PowerState,
    @{N='SyncTimeWithHost';E={$_.ExtensionData.Config.Tools.SyncTimeWithHost}},
    @{N='ToolsStatus';E={$_.ExtensionData.Guest.ToolsStatus}} | Sort-Object Host, Name | Format-Table -AutoSize
# Đồng bộ một lần đã bị tắt chưa (không có dòng nào = mặc định, Tools vẫn đồng bộ một lần)
$vms | Get-AdvancedSetting -Name 'time.synchronize*' | Select-Object Entity, Name, Value
```

**Điều kiện DỪNG** (gặp một điều là không đổi giờ host, báo Đăng, cập nhật CR):
1. Có guest lệch theo host (≈ −19 / −25 phút) hoặc lệch ≥ 1 phút so với 10.179.120.20 (#3, #4).
2. Có VM trên .45 / .47 bật "Synchronize guest time with host" (#2).
3. Không xác định được nguồn giờ của domain PCCE3, hoặc PDC chạy trên .45 / .47 mà không có nguồn NTP ngoài (#5).
4. Baseline đang lỗi (#6–#14): service dừng, Router / Logger không duplex, PG / CG mất một side, Finesse không IN_SERVICE, replication khác 2, CVP / CUIC / LiveData lỗi, có alert mới.
5. Đang có sự cố hoặc ticket mở, đang giờ cao điểm, VTB chưa xác nhận cửa sổ, trùng go-live uCRM v5 hoặc change khác, có job snapshot trong cửa sổ (#15, #16).

### C. Verify tầng ứng dụng sau mỗi host

Trình tự: .47 → checklist → quan sát 15–30 phút, qua ít nhất 1 ranh giới interval → Đăng quyết định Go / No-go → .45 → checklist → quan sát 30 phút → đóng CR.

| Thời điểm | Kiểm tra | Kết quả mong đợi |
|---|---|---|
| T+0 | `infra-sentinel` xác nhận giờ host khớp 10.179.120.20, ntpd Running (CR bước 1.3 / 2.3) | Lệch ≤ 2 s. Host lưu giờ UTC: chỉnh theo CR bước 1.1 / 2.1 (ưu tiên PowerCLI `UpdateDateTime` theo UTC; nếu dùng UI thì verify ngay), vì nhập nhầm múi giờ sẽ làm host lệch khoảng 7 giờ |
| T+5 | Lặp #3, #4 trên mọi VM của host vừa đổi, rồi trên một VM ở side kia | Offset không đổi so với pre-check (≤ 2 s); Event Viewer không có sự kiện Time-Service đặt lại giờ, không có lỗi Kerberos skew |
| T+5–10 | Lặp #6–#12 | Như baseline; PG / CG giữ nguyên side active; Router vẫn duplex |
| T+10–15 | #15 (số agent, cuộc gọi); #17 cuộc gọi test nếu được phép | Không có logout hàng loạt; cuộc gọi test thông, screen pop lên, bản ghi âm đúng giờ |
| Ranh giới interval + 5 phút | Report interval trên CUIC, hoặc SQL Q1 trên HDS | Interval liên tục theo bước 15 / 30 phút, không hụt, không trùng |
| T+15–30 | Chụp output đưa vào CR; Đăng quyết định | Mọi mục đạt → làm .45; có mục lỗi → sang mục D, không làm .45 |

```sql
-- Q1: chạy trên HDS (DB <inst>_hds), chỉ đọc, giới hạn 3 giờ [cần xác minh tên bảng trên 12.x]
SELECT DateTime, COUNT(*) AS SoDong
FROM t_Call_Type_Interval WITH (NOLOCK)
WHERE DateTime >= DATEADD(HOUR, -3, GETDATE())
GROUP BY DateTime ORDER BY DateTime;
```

Sau .45: chạy lại bảng trên, chú ý các VM side A (Rogger A, CUCM publisher, Finesse primary nếu nằm ở A [SL]). So giờ guest A với B lần cuối, quan sát 30 phút, ghi kết quả vào CR. Theo dõi thêm: sau lần reboot hoặc snapshot đầu tiên của từng VM PCCE3 kể từ change, kiểm lại giờ guest, vì đồng hồ RTC ảo của VM có thể còn mang độ lệch cũ [SL].

### D. Ứng phó / rollback tầng ứng dụng

Không "rollback" bằng cách đặt giờ host về giờ cũ. Làm vậy tái tạo rủi ro R-014 và có thể khiến guest nhảy thêm một lần nữa theo chiều **lùi**; với dữ liệu interval / TCD, nhảy lùi nguy hiểm hơn nhảy tiến [SL]. Guest nào lệch thì sửa ở guest đó.

**Làm ngay, trong phạm vi CR** (Đăng duyệt kèm CR; báo Đăng trước khi chạy; chỉ trên VM bị lệch):
1. Windows lệch: chạy `w32tm /resync /rediscover`, rồi lặp #3 tới khi offset ≤ 2 s.
2. VOS báo "unsynchronised" hoặc còn lệch sau 10–15 phút: xem lại `utils ntp status`; chỉ khi vẫn lệch mới chạy `utils ntp restart` (chỉ restart dịch vụ NTP, không restart ứng dụng).
3. Có guest trên .47 bị nhảy giờ → không làm .45. Ghi lại khoảng thời gian mà dữ liệu báo cáo / ghi âm có thể sai, để Đăng báo VTB nếu cần.

**Dừng và lập CR mới** (không làm trong CR này):
- Restart service ICM (Router, Logger, PG, CG, AW / HDS) hoặc CVP; restart Finesse Tomcat / Notification Service; restart Cisco CallManager / CTIManager; `utils dbreplication reset` / `repair`.
- Failover hoặc ép chuyển side PG / CG. Nếu PG / CG tự chuyển side mà dịch vụ vẫn chạy → giữ nguyên, chỉ ghi nhận.
- Reboot VM; đổi nguồn NTP hay cấu hình w32time của PDC / VOS; đổi VMware Tools settings (Sync, `time.synchronize.*`); cấp lại cert.
- Agent logout hàng loạt, Finesse OUT_OF_SERVICE hoặc cuộc gọi không được định tuyến → coi là sự cố: báo Đăng ngay, Đăng báo VTB theo kênh đã thống nhất, mở `incident-rca`. Khi dựng timeline, nhớ rằng log của host trước change chậm 19 / 25 phút.

### E. Cửa sổ và thông báo

- **Cửa sổ:** contact center ngân hàng có thể chạy 24/7 [SL], nên chọn khung ít cuộc gọi nhất theo số liệu CUIC (lượng gọi theo giờ, 2–4 tuần gần nhất) và thống nhất bằng văn bản với VTB. Cần tránh:
  - ngày go-live uCRM v5 và 1–2 ngày quanh đó. Email 2026-11-23 chỉ nói "sắp go-live"; chữ "live 2026-11-24" trong [[VietinBank]] nhiều khả năng là ngày đọc vCenter, không phải ngày go-live [SL] → cần hỏi lịch go-live [cần xác minh];
  - change khác trên PCCE3 / uCRM / mạng FHN01, khung backup, và ngày cao điểm của ngân hàng [SL].
- **Thời lượng dự kiến** [SL]: pre-check nhanh 30 phút + .47 khoảng 10 phút + quan sát 15–30 phút + .45 khoảng 10 phút + quan sát 30 phút, tổng ≈ 1,5–2 giờ.
- **Standby:** Đăng (điều phối, vSphere); kỹ sư PCCE / voice BaseBS có quyền vào ICM, CUCM, Finesse, CUIC; đầu mối đội uCRM v5 (CTI, screen pop); supervisor tổng đài VTB (xác nhận agent, cuộc gọi); người theo dõi Calabrio nếu có. Tên và số liên hệ: [cần điền].

#### Mẫu thông báo gửi VietinBank (nháp, Đăng tự chỉnh và gửi)

> **Tiêu đề:** [BaseBS] Thông báo bảo trì: đồng bộ thời gian hạ tầng tổng đài PCCE3, ngày <ngày>
>
> Kính gửi Bộ phận vận hành Contact Center VietinBank,
>
> BaseBS xin thông báo kế hoạch bảo trì như sau:
> - **Mục đích:** đồng bộ lại thời gian (NTP) cho 02 máy chủ ảo hóa đang chạy hệ thống tổng đài PCCE3, để thời gian hệ thống chính xác và thống nhất (log, báo cáo, ghi âm).
> - **Thời gian dự kiến:** từ <giờ bắt đầu> đến <giờ kết thúc> ngày <ngày> (giờ Việt Nam). Thực hiện lần lượt từng máy chủ, có kiểm tra giữa hai bước.
> - **Ảnh hưởng dự kiến:** không gián đoạn cuộc gọi, không ảnh hưởng thao tác của điện thoại viên; không khởi động lại máy chủ hay ứng dụng.
> - BaseBS theo dõi hệ thống trong suốt thời gian thực hiện; nếu phát hiện bất thường sẽ dừng ngay và thông báo cho Quý Ngân hàng.
> - **Đề nghị:** Quý Ngân hàng xác nhận khung giờ trên và (nếu được) cử một đầu mối giám sát tổng đài cùng phối hợp. Nếu điện thoại viên không đăng nhập được, không nhận được cuộc gọi hoặc thông tin không hiển thị trên CRM, vui lòng báo ngay cho đầu mối BaseBS.
>
> Đầu mối BaseBS: <họ tên> – <điện thoại> – <email>
>
> Trân trọng,
> <người gửi, chức danh>

## Các bước thực hiện
| # | Lệnh | Verify (kết quả mong đợi) | Rollback |
|---|---|---|---|
| 0 | Pre-check read-only 0a, 0c–0f (0b không áp dụng); **chạy checklist cc-echo mục B** | Mọi tiêu chí đạt | Chỉ đọc. Không đạt → DỪNG, cập nhật CR, xin duyệt lại |
| 1.1 | .47 (PCCE3-B): chỉnh giờ tay về giờ chuẩn (nhảy tiến ≈ 19 phút) | Lệch ≤ 60 s | R-1: không có rollback có nghĩa; guest nhảy giờ → **chạy checklist cc-echo mục D** |
| 1.2 | .47: policy On, Start ntpd; server giữ 10.179.120.20; firewall giữ Enabled | Server 10.179.120.20, firewall True, Running True, Policy on | R-2 theo 0a: Stop ntpd, policy cũ (server, firewall không đổi) |
| 1.3 | .47: chờ 10–15 phút, verify host; **chạy checklist cc-echo mục C** | Lệch ≤ 2 s; Connected; không alarm mới (ngoài alarm quạt có sẵn); mục C đạt | Không đạt → DỪNG, không sang .45; ứng phó theo **mục D** |
| 1.4 | Quan sát 15–30 phút (side B đã đổi, side A chưa) | Không alarm / event / lỗi ứng dụng mới; cc-echo xác nhận side B ổn | Có lỗi → DỪNG, **mục D** |
| 2.1 | .45 (PCCE3-A): chỉnh giờ tay (nhảy tiến ≈ 25 phút) | Lệch ≤ 60 s | Như 1.1 |
| 2.2 | .45: như 1.2 | Như 1.2 | Như 1.2 |
| 2.3 | .45: verify host; **chạy checklist cc-echo mục C** | Như 1.3 (không có alarm quạt) | Không đạt → DỪNG, **mục D** |
| 3 | Sau 24 giờ: verify lại 2 host; **chạy checklist cc-echo mục C** | Lệch ≤ 2 s, Running, Policy on; mục C đạt | Lệch lại → mở sự cố, không tự sửa ngoài CR |

## Chi tiết lệnh
Dùng chung (PowerShell + PowerCLI; Đăng tự `Connect-VIServer -Server 10.179.110.10`, không ghi thông tin đăng nhập vào CR). Ký hiệu x = 1 (.47), 2 (.45).
```powershell
$names = '10.179.110.47','10.179.110.45'   # side B trước, side A sau
$dMay  = <Δmáy từ 0f>                      # giây, dương = máy Đăng nhanh (25/11 ≈ +13). Cố ý để trống: chưa điền thì PowerShell báo lỗi
function Get-HostOffset($h) {               # lệch thật của host (giây) = (giờ host − giờ máy) + Δmáy
  $dts = Get-View $h.ExtensionData.ConfigManager.DateTimeSystem
  ($dts.QueryDateTime().ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds + $dMay
}
```
- Bắt buộc `.ToUniversalTime()` ở cả hai vế: PowerCLI có thể trả `QueryDateTime()` theo giờ local. Kết quả lệch đúng ±7 giờ so với kỳ vọng nghĩa là phép đo nhầm múi giờ, không phải lỗi host.
- **Làm 0f trước tiên** (0a, 0d cần Δmáy). Chạy lại 0f ngay trước mỗi lần verify ngưỡng 2 s, vì đồng hồ máy Đăng có thể tự đồng bộ giữa chừng.

### 0a. Ghi cấu hình hiện tại (để rollback)
UI: mỗi host → Configure → System → Time Configuration (chụp màn hình); Monitor → Triggered Alarms (gồm cả alarm đã ack).
```powershell
foreach ($n in $names) {
  $h = Get-VMHost -Name $n
  "=== $n   lệch = $([math]::Round((Get-HostOffset $h), 1)) s"
  Get-VMHostNtpServer -VMHost $h
  Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Select-Object Name, Enabled
  Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd' | Select-Object Key, Running, Policy
  $h.ExtensionData.TriggeredAlarmState |
    Select-Object @{N='Alarm';E={(Get-View $_.Alarm).Info.Name}}, OverallStatus, Time, Acknowledged
}
Get-Cluster -Name 'PCCE Cluster03' |
  Select-Object Name, HAEnabled, HAIsolationResponse, DrsEnabled, DrsAutomationLevel
```
- Mong đợi: server 10.179.120.20, firewall True, Running False; lệch ≈ −19 phút (.47) / −25 phút (.45), có thể trôi thêm vài phút; alarm chỉ có quạt .47 (Critical, đã ack).
- Cấu hình khác, hoặc lệch khác bảng > 10 phút (tức có người đã đổi từ 25/11) → **DỪNG**.
- Ghi HA / DRS của cluster. HA ON → thêm kiểm tra DasHostState ở bước verify.

### 0b. Không áp dụng
Giữ 10.179.120.20 (nguồn đã chứng minh, xem "Mục tiêu và lý do"). 0f kiêm xác nhận 10.179.120.20 trả lời NTP.

### 0c. VM đồng bộ giờ theo host
```powershell
foreach ($n in $names) {
  Get-VMHost -Name $n | Get-VM |
    Select-Object @{N='Host';E={$n}}, Name, PowerState,
      @{N='SyncTimeWithHost';E={$_.ExtensionData.Config.Tools.SyncTimeWithHost}} |
    Where-Object SyncTimeWithHost -ne $false
}
Get-VM -Name '*PCCE3*' | Select-Object Name, VMHost, PowerState    # VM PCCE3 nằm ngoài .45 / .47
```
- Mong đợi: vòng lặp đầu không ra dòng nào (mọi VM False). **Có VM True → DỪNG**, liệt kê, cập nhật CR (rủi ro Cao, kế hoạch riêng cùng cc-echo), xin duyệt lại.
- VM PCCE3 nằm trên FHN01 .22 (≈ +7 giờ 58 phút) hoặc .53 (≈ −1 giờ) → ghi lại, ưu tiên CR tiếp theo. [cần xác minh] 21 VM PCCE3 ở [[FHN01]] được đếm theo tên hay theo folder.

### 0d. Vị trí VCSA, DC và chế độ giờ của VCSA
```powershell
Get-VM | Where-Object { $_.Guest.IPAddress -contains '10.179.110.10' -or $_.Guest.IPAddress -contains '10.179.120.20' -or $_.Name -match 'VCSA|vCenter' } |
  Select-Object Name, VMHost, PowerState
((Get-View ServiceInstance).CurrentTime().ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds + $dMay   # lệch đồng hồ vCenter
```
- VAMI `https://10.179.110.10:5480` → Time: chế độ (Disabled / Host / NTP) và server.
- VCSA ở chế độ Host **và** nằm trên .45 / .47 → **DỪNG**, xử lý riêng. [SL] VCSA và AD CN247 nhiều khả năng chạy ở A-App, khi đó không bị ảnh hưởng.
- Đồng hồ vCenter lệch > 60 s → ghi nhận, đưa vào CR tiếp theo; không chặn CR này.

### 0e. Job trong cửa sổ
- vCenter → Recent Tasks, Scheduled Tasks; `Get-Task | Where-Object State -eq 'Running'`. Lịch backup VM PCCE3 (nếu có) [cần xác minh], Đăng xác nhận. Job tầng ứng dụng: theo checklist cc-echo mục B.
- Mong đợi: không có backup / snapshot / vMotion / nâng cấp VMware Tools / reboot VM nào trên .45 / .47 trong cửa sổ, vì các sự kiện này kích hoạt đồng bộ giờ một lần. Có → dời cửa sổ.

### 0f. Sai số đồng hồ máy Đăng
```bat
w32tm /stripchart /computer:10.179.120.20 /samples:3 /dataonly
```
- Chạy trên chính máy dùng PowerCLI. Offset o = giờ server − giờ máy [cần xác minh dấu: 25/11 máy nhanh ≈ 13 s nên mong đợi o ≈ −13 s]. Điền `$dMay = −o`.
- Máy Đăng không tới được 10.179.120.20 (UDP 123): lấy Δmáy từ một host A-App đang đồng bộ tốt, ví dụ .21 (HC25 §3.4): `$dMay = -((Get-View (Get-VMHost -Name 10.179.110.21).ExtensionData.ConfigManager.DateTimeSystem).QueryDateTime().ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds`.

### 1.1 / 2.1. Chỉnh giờ tay
```powershell
$h   = Get-VMHost -Name <IP>
$dts = Get-View $h.ExtensionData.ConfigManager.DateTimeSystem
$dts.UpdateDateTime((Get-Date).ToUniversalTime().AddSeconds(-$dMay))   # đặt về giờ chuẩn
Get-HostOffset $h                                                      # mong đợi trị tuyệt đối ≤ 60 s
```
- Lý do làm trước: 19 phút ≈ 1140 s và 25 phút ≈ 1500 s, đều > 1000 s. ntpd mặc định coi độ lệch > 1000 s là vượt "sanity limit" và không chỉnh [cần xác minh trên ESXi 6.5]. Chỉnh tay trước an toàn trong mọi trường hợp.
- UI tương đương: Time Configuration → Edit → "Manually configure the date and time on this host" → nhập giờ. **Lưu ý:** UI hiển thị theo múi giờ trình duyệt, host lưu UTC; nhập nhầm múi giờ là kiểu lỗi [SL] có thể đã gây lệch khoảng +8 giờ ở các site khác (HC25 §2.2) → verify ngay bằng `Get-HostOffset`.
- [cần xác minh] Trên client 6.5, chọn "Manually configure" có thể tắt NTP client; bước x.2 kiểm tra và bật lại.
- Ghi giờ chính xác lúc chỉnh vào "Kết quả thực tế": log vmkernel / hostd sẽ có bước nhảy tại thời điểm này.

### 1.2 / 2.2. Bật ntpd (server giữ nguyên)
```powershell
$h = Get-VMHost -Name <IP>
Get-VMHostNtpServer -VMHost $h                                                      # phải đúng 10.179.120.20; khác → DỪNG
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Select-Object Enabled   # True (theo 0a)
# Chỉ khi dòng trên ra False (ví dụ x.1 làm bằng UI đã tắt NTP client):
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Set-VMHostFirewallException -Enabled $true
$svc = Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd'
Set-VMHostService   -HostService $svc -Policy On          # = "Start and stop with host"
Start-VMHostService -HostService $svc -Confirm:$false
```
UI: Edit Time Configuration → "Use Network Time Protocol (Enable NTP client)" → NTP Servers giữ 10.179.120.20 → NTP Service Startup Policy "Start and stop with host" → Start → OK.

### 1.3 / 2.3 / 3. Verify
```powershell
$h = Get-VMHost -Name <IP>
Get-VMHostNtpServer -VMHost $h                                                              # 10.179.120.20
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Select-Object Enabled           # True
Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd' | Select-Object Running, Policy  # True, on
$h.ConnectionState                                                                          # Connected
$h.ExtensionData.Runtime.DasHostState.State                                                 # chỉ khi 0a thấy HA ON: master / connectedToMaster
Get-VIEvent -Entity $h -Start (Get-Date).AddMinutes(-30) | Select-Object CreatedTime, FullFormattedMessage
Get-HostOffset $h                                                                           # sau 10–15 phút: trị tuyệt đối ≤ 2 s
```
- UI: NTP Client Enabled, Service Running, server 10.179.120.20, policy "Start and stop with host"; Triggered Alarms không có alarm mới so với 0a (alarm quạt .47 là có sẵn). Events có thể có sự kiện đổi giờ kiểu "system clock stepped" (HC25 §3.1): bình thường.
- Sau khi host đạt: **chạy checklist cc-echo mục C**. Mục C không đạt → DỪNG, ứng phó theo **mục D**.
- Bước 3 (sau 24 giờ): chạy khối này cho cả 2 host, rồi **chạy checklist cc-echo mục C**.

### 1.4. Quan sát giữa 2 host
15–30 phút sau khi .47 đạt 1.3: theo dõi Triggered Alarms / Events của .47 và các VM trên đó; cc-echo xác nhận side B ổn theo mục C. Chỉ sang 2.1 khi không có lỗi mới.

### Rollback
- **R-1 (chỉnh giờ tay): không có rollback có nghĩa.** Không đưa host về giờ sai. Đặt nhầm (lệch > 60 s) thì chạy lại x.1.
- **R-2 (bật ntpd): khôi phục đúng giá trị 0a.** Dùng khi cấu hình mới gây lỗi, hoặc ntpd kéo giờ host xa UTC (lệch > 5 s và tăng dần): chạy R-2, chạy lại x.1 để host không ở giờ sai, rồi DỪNG CR.
```powershell
$h   = Get-VMHost -Name <IP>
$svc = Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd'
Stop-VMHostService -HostService $svc -Confirm:$false                  # 0a: Stopped
Set-VMHostService  -HostService $svc -Policy <Off / On / Automatic theo 0a>
# Server không đổi trong CR này. Firewall: chỉ chạy nếu hiện tại khác giá trị 0a (0a mong đợi True)
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Set-VMHostFirewallException -Enabled <giá trị 0a>
```
  UI: Edit Time Configuration → đặt lại đúng như ảnh chụp 0a.
- **R-G (guest bị nhảy giờ):** VM PCCE3 (Windows hoặc Cisco VOS): **chỉ xử lý theo checklist cc-echo mục D**, không tự chạy lệnh trong guest. VM khác (nếu có): Windows `w32tm /resync /rediscover`; Linux chrony `chronyc makestep`; Linux ntpd `systemctl restart ntpd` (nếu chạy với `-g`) hoặc dừng ntpd, `ntpdate -u <server>`, rồi start lại. Thao tác nặng hơn (restart service ứng dụng, failover PCCE) chỉ qua CR mới.

### Điều kiện dừng (không sang host kế tiếp)
- Host Disconnected / Not responding. Nếu tự Connected lại trong ≤ 5 phút: ghi nhận, hỏi Đăng trước khi đi tiếp.
- Alarm mới trên host hoặc VM so với 0a; lỗi HA agent (nếu HA ON).
- Checklist cc-echo mục C không đạt, hoặc VietinBank / người trực báo lỗi cuộc gọi, agent, CTI, báo cáo, ghi âm.
- Sau 30 phút lệch vẫn > 2 s: giữ nguyên trạng thái (giờ đã chỉnh tay vẫn tốt hơn hiện trạng), báo Đăng. [SL] Nghi rule FortiGate theo từng IP host chặn UDP 123 (5 host A-App cùng dải 10.179.110.x vẫn đồng bộ được, nên ít khả năng chặn cả dải).
- Một bước lỗi: thử lại tối đa 2 lần sau khi đã sửa nguyên nhân (CLAUDE.md §4.9).

## Ngoài phạm vi: CR tiếp theo (không gộp vào CR này)
- FHN01 .22 (A-App): trỏ nhầm 10.189.120.20 (NTP của SMB), ≈ +7 giờ 58 phút → đổi sang 10.179.120.20, chỉnh lùi khoảng 8 giờ. FHN01 .53 (A-CCX): NTP Disabled, server trống, ≈ −1 giờ (HC25 §3.4). Cùng vCenter, nên làm ngay sau CR này; ưu tiên cao hơn nếu 0c thấy VM PCCE3 trên .22 / .53.
- **Gấp trước go-live uCRM v5:** `VTB_uCRMv5_DB01` 172.31.90.101 chạy trên FHN01 .22 ([[VietinBank]], live 24/11), host này lệch ≈ +7 giờ 58 phút (HC25 §3.4). [SL] Một lần snapshot / backup DB01 có thể kéo guest tiến khoảng 8 giờ → CR NTP cho .22 nên làm trước go-live (cc-echo mục A).
- SMB 3 host: CR riêng [[2026-11-27-ntp-esxi-smb]]. FPTDC .178 / .188; VDC 5 host ([[2026-11-24-vsphere-health-VDC]]).
- R-018 quạt .47: CR phần cứng riêng (cần bảo trì). Có điều kiện: CR chuyển VCSA FHN01 sang NTP nếu 0d thấy chế độ Host hoặc lệch giờ.

## Phê duyệt
- Người duyệt: Đăng
- Thời điểm duyệt:

## Kết quả thực tế
### Pre-check (bước 0)
| Mục | Kết quả (giá trị, giờ đo UTC+7) | Đạt? |
|---|---|---|
| 0a .47: server / firewall / Running / Policy / lệch / alarm | | |
| 0a .45: như trên | | |
| 0a PCCE Cluster03: HA / isolation / DRS | | |
| 0c VM có SyncTimeWithHost khác False; VM PCCE3 nằm ngoài .45 / .47 | | |
| 0d VCSA ở host nào, chế độ giờ, lệch đồng hồ vCenter; AD 10.179.120.20 ở host nào | | |
| 0e Task / backup / snapshot trong cửa sổ | | |
| 0f Offset o máy Đăng → Δmáy; 10.179.120.20 trả lời NTP | | |
| Checklist cc-echo mục B | | |

### Thực thi
| Bước | Thời gian (UTC+7) | Output verify | Ghi chú |
|---|---|---|---|
| 1.1 .47 chỉnh giờ tay | | | |
| 1.2 .47 bật ntpd | | | |
| 1.3 .47 verify + cc-echo mục C | | | |
| 1.4 Quan sát 15–30 phút | | | |
| 2.1 .45 chỉnh giờ tay | | | |
| 2.2 .45 bật ntpd | | | |
| 2.3 .45 verify + cc-echo mục C | | | |
| 3 Sau 24 giờ + cc-echo mục C | | | |

### Đóng CR
- Trạng thái cuối:
- Việc còn mở:
- Note đã cập nhật: [[FHN01]] (mục NTP), [[VietinBank]] (mục Lưu ý PCCE3), [[risk-register]] R-014
