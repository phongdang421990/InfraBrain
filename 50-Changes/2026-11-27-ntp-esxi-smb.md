---
type: change
status: draft
risk: TB
window: "Ngoài giờ cao điểm Connect247, ngoài lịch backup; giờ cụ thể Đăng chốt"
systems: ["[[FSG02]]", "ESXi 10.189.110.22", "ESXi 10.189.110.21", "ESXi 10.189.110.25", "vCenter 10.189.110.10"]
customer: "Connect247 Cloud (đa tenant), CRM VietJet, VinHMS"
updated: 2026-11-27
tags: [change, ntp, esxi, vsphere, fsg02, smb, connect247, R-014]
---
# CR: Chỉnh giờ và bật NTP cho 3 host ESXi SMB Cluster-01 (10.189.110.21 / .22 / .25)

> **Bản nháp, chưa thực thi gì.** `infra-sentinel` soạn ngày 2026-11-27, không truy cập hệ thống nào khi soạn. Chỉ thực hiện khi Đăng gõ "DUYỆT" cho đúng CR này.
> Nguồn chính: [[2026-11-25-vsphere-health-FSG-FHN]] (gọi tắt **HC25**), đọc live vSphere UI ngày 25/11; lệch giờ đo bằng cách so "Date & Time" của host với đồng hồ trình duyệt, sai số ±10 s. Nhãn: **[SL]** = suy luận; **[cần xác minh]** = chưa có bằng chứng.

## Mục tiêu và lý do
Hiện trạng, **đã xác minh** live 25/11 (HC25 §2.2, §3.3), xếp theo thứ tự thực thi:

| Host | Model / ESXi | VM | NTP client (firewall) / ntpd | Server | Lệch (host − chuẩn) |
|---|---|---|---|---|---|
| 10.189.110.22 | R740, 6.5.0 b13635690 | 29 | Enabled / Stopped | 10.189.120.20 | ≈ −2 giờ 24 phút |
| 10.189.110.21 | R740, 6.5.0 b13635690 | 30 | Disabled / Running | 10.189.120.20 | ≈ −4 giờ 13 phút |
| 10.189.110.25 | R650xs, 6.5.0 b19092475 | 50 | Disabled / Stopped | (trống) | ≈ +8 giờ 01 phút |

- Hệ quả ([[risk-register]] R-014, mức Rất cao; HC25 §2.2): VMware Tools đồng bộ giờ một lần cho guest khi tạo / revert snapshot (backup), vMotion, resume, khi Tools khởi động, nên guest có thể nhảy giờ hàng giờ. Log và timeline RCA sai; lỗi Kerberos / AD, TLS / SIP.
- Mục tiêu: cả 3 host lệch ≤ 2 s so với UTC; NTP client Enabled, ntpd Running, policy "Start and stop with host", đúng **một** server S.
- **Nguồn NTP cho SMB chưa chắc:**
  - 10.189.120.20 (đang cấu hình trên .21 / .22) không có trong inventory nào. AD SMB là 10.189.120.21 ([[FSG02]] mục Dịch vụ chính; [[BaseBS-Infra-Master-Overview-Appendix-IP]] mục C).
  - Mẫu ở site khác: .120.20 là PDC / AD, .120.21 là VM NTP riêng (VDC: [[2026-11-24-vsphere-health-VDC]] §3; FHN02: HC25 §3.5 và Appendix IP mục E).
  - → Mặc định đề xuất **S = 10.189.120.21**, chốt ở pre-check 0b. CR này được duyệt cho đúng 2 giá trị S = .21 hoặc .20; giá trị khác → cập nhật CR, xin duyệt lại.
  - Chỉ đặt 1 server: với 2 nguồn chưa kiểm chứng, ntpd không phân biệt được nguồn nào sai. Nguồn thứ 2–3 để cho CR chuẩn hóa NTP sau.

## Phạm vi ảnh hưởng
- Hệ thống: [[FSG02]]; vCenter vcsa.smbbasebs.com 10.189.110.10 (6.5.0 b15259038), datacenter "SMB", Cluster-01: 3 host, 109 VM (HC25 §3.3). Dịch vụ: Connect247 Cloud (đa tenant), CRM VietJet, VinHMS ([[FSG02]]).
- Gián đoạn: **Không** (dự kiến). Không maintenance mode, không reboot, không vMotion. Thời lượng: khoảng 60–75 phút, chưa tính kiểm tra sau 24 giờ.
- Cluster (HC25 §2.3, §3.3; R-025): HA ON (master .22) nhưng Host failure response = Disabled; isolation, APD, PDL, VM monitoring đều Disabled; DRS off; RAM 86%. → [SL] Nếu HA bầu lại master khi đổi giờ .22 thì cũng không VM nào bị restart hay bị tắt.
- **Mức rủi ro đề xuất: TB.** Bước nhảy giờ lớn (tới 8 giờ, có một bước lùi) trên host production 109 VM, có thể đang chứa vCenter và DC. Bù lại: chỉ đổi tầng host; guest không đổi giờ theo host trừ khi VMware Tools đồng bộ (khống chế bằng 0c, 0e); rollback cấu hình đơn giản; làm từng host một.
- Rủi ro cụ thể và cách chặn:
  - Guest nhảy giờ do "Synchronize guest time with host", hoặc do snapshot / vMotion / Tools restart trong cửa sổ → 0c, 0e.
  - VCSA ở chế độ giờ Host và nằm trên host mục tiêu → vCenter nhảy giờ theo → 0d.
  - [SL] Nhảy giờ lớn có thể làm host báo Not responding thoáng qua → điều kiện dừng.
  - [SL] VM không có NTP riêng có thể đang "theo" giờ host sai sau mỗi lần snapshot backup. Lần backup đầu tiên sau change sẽ kéo các VM này về giờ đúng (nhảy một lần) → kiểm tra ở bước 4.
- Thông báo cho: nội bộ (trực vận hành, team Connect247 / SMB). Khách hàng: không bắt buộc vì không gián đoạn (Đăng quyết).

## Điều kiện tiên quyết
- [ ] Pre-check 0a–0f xong, ghi vào "Kết quả thực tế", mọi tiêu chí đạt
- [ ] Cửa sổ đã chốt: ngoài giờ cao điểm Connect247, không trùng lịch backup
- [ ] PowerCLI kết nối được 10.189.110.10, Đăng tự đăng nhập. HC25 chỉ dùng UI, PowerCLI chưa được thử với vCenter này (HC25 §5 mục 12) [cần xác minh]. Không dùng được → làm bằng UI và ghi "chưa đo được ngưỡng 2 s" (UI chỉ chính xác ±10 s)
- [ ] (Tùy chọn) Backup cấu hình host: `Get-VMHostFirmware -VMHost $h -BackupConfiguration -DestinationPath <thư mục>`. Chỉ để lưu; restore bundle cần maintenance mode và reboot nên **không** dùng làm rollback cho CR này
- [ ] **Không** tạo snapshot VM: không cần (thay đổi ở tầng host) và không nên (tạo snapshot gây đồng bộ giờ một lần cho guest)
- [ ] Đã thông báo nội bộ; người hỗ trợ standby: ____

## Các bước thực hiện
| # | Lệnh | Verify (kết quả mong đợi) | Rollback |
|---|---|---|---|
| 0 | Pre-check read-only 0a–0f | Mọi tiêu chí đạt; chốt S | Chỉ đọc. Không đạt → DỪNG, cập nhật CR, xin duyệt lại |
| 1.1 | .22: chỉnh giờ tay về giờ chuẩn (nhảy tiến ≈ 2 giờ 24 phút) | Lệch ≤ 60 s | R-1: không có rollback có nghĩa; guest nhảy giờ → R-G |
| 1.2 | .22: server = S (thay .120.20 nếu S ≠ .20); firewall NTP Client giữ Enabled; policy On; Start ntpd | Server S, firewall True, Running True, Policy on | R-2 theo 0a: server .120.20, firewall True, Stopped |
| 1.3 | .22: chờ 10–15 phút rồi verify | Lệch ≤ 2 s; Connected; HA master / connectedToMaster; không alarm mới | Không đạt → DỪNG, không sang .21 |
| 2.1 | .21: chỉnh giờ tay (nhảy tiến ≈ 4 giờ 13 phút) | Lệch ≤ 60 s | R-1, R-G |
| 2.2 | .21: server = S; firewall Disabled → Enabled; policy On; **Restart** ntpd (đang Running) | Như 1.2 | R-2 theo 0a: server .120.20, firewall False, Running |
| 2.3 | .21: verify như 1.3 | Như 1.3 | Không đạt → DỪNG, không sang .25 |
| 3.1 | .25: chỉnh giờ tay (**nhảy lùi** ≈ 8 giờ 01 phút; nhiều VM nhất nên làm cuối) | Lệch ≤ 60 s | R-1, R-G |
| 3.2 | .25: thêm S (đang trống); firewall Disabled → Enabled; policy On; Start ntpd | Như 1.2 | R-2 theo 0a: không server, firewall False, Stopped |
| 3.3 | .25: verify như 1.3 | Như 1.3 | Không đạt → DỪNG, báo Đăng |
| 4 | Sau 24 giờ: chạy lại khối verify cho cả 3 host | Lệch ≤ 2 s, Running, Policy on; không lỗi giờ sau lần backup đầu tiên | Lệch lại → mở sự cố, không tự sửa ngoài CR |

## Chi tiết lệnh
Dùng chung (PowerShell + PowerCLI; Đăng tự `Connect-VIServer -Server 10.189.110.10`, không ghi thông tin đăng nhập vào CR). Ký hiệu x = 1, 2, 3 theo host.
```powershell
$names = '10.189.110.22','10.189.110.21','10.189.110.25'   # đúng thứ tự thực thi
$S     = '10.189.120.21'      # S chốt ở 0b: '10.189.120.21' hoặc '10.189.120.20'
$dMay  = <Δmáy từ 0f>         # giây, dương = máy Đăng nhanh (25/11 ≈ +13). Cố ý để trống: chưa điền thì PowerShell báo lỗi
function Get-HostOffset($h) {  # lệch thật của host (giây) = (giờ host − giờ máy) + Δmáy
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
```
Mong đợi: cấu hình khớp bảng "Hiện trạng"; lệch gần như bảng (có thể trôi thêm vài phút). Cấu hình khác, hoặc lệch khác bảng > 10 phút (tức có người đã đổi từ 25/11) → **DỪNG**.

### 0b. Chọn nguồn NTP S
Trên một máy Windows trong SMB (Đăng chọn):
```bat
w32tm /stripchart /computer:10.189.120.20 /samples:5 /dataonly
w32tm /stripchart /computer:10.189.120.21 /samples:5 /dataonly
w32tm /stripchart /computer:10.179.120.20 /samples:5 /dataonly
```
Trên DC 10.189.120.21 (Đăng tự đăng nhập):
```bat
w32tm /query /source
w32tm /query /status
```
VM nào đang giữ IP .20 / .21 và nằm trên host nào:
```powershell
Get-VM | Where-Object { $_.Guest.IPAddress -match '^10\.189\.120\.2[01]$' } | Select-Object Name, VMHost, PowerState
```
Tiêu chí:
- Server trả lời đủ 5 mẫu, không lỗi / timeout.
- Chênh giữa offset của S và offset của 10.179.120.20 ≤ 1 s. 10.179.120.20 là nguồn đã chứng minh: 5 host A-App FHN01 dùng nó đều lệch ≈ 0 (HC25 §3.4; [[FHN01]]).
- Nguồn của DC không phải "Local CMOS Clock", "Free-running System Clock", "VM IC Time Synchronization Provider" hay VMware Tools; `/query /status` có Leap Indicator 0 và Last Successful Sync Time gần đây.
- Ưu tiên .21. **Không server nào đạt → DỪNG** (cần CR sửa nguồn giờ của AD SMB trước).
- Máy trong SMB không tới được 10.179.120.20 → chạy cả 3 lệnh stripchart từ máy Đăng (như 0f); vẫn không đo được → DỪNG.
- [SL] Nếu .21 thực ra là VM NTP Linux (theo mẫu VDC / FHN02) chứ không phải DC: kiểm tra bằng `chronyc tracking` hoặc `ntpq -p` (stratum hợp lệ, không chạy theo LOCAL clock).

### 0c. VM đồng bộ giờ theo host
```powershell
foreach ($n in $names) {
  Get-VMHost -Name $n | Get-VM |
    Select-Object @{N='Host';E={$n}}, Name, PowerState,
      @{N='SyncTimeWithHost';E={$_.ExtensionData.Config.Tools.SyncTimeWithHost}} |
    Where-Object SyncTimeWithHost -ne $false
}
```
Mong đợi: không có dòng nào (mọi VM False). **Có VM True → DỪNG**, liệt kê, cập nhật CR. VM đang tắt mà True: ghi riêng; [SL] VM này không bị ảnh hưởng ngay, Đăng quyết khi cập nhật CR.

### 0d. Vị trí VCSA, DC và chế độ giờ của VCSA
```powershell
Get-VM | Where-Object { $_.Guest.IPAddress -contains '10.189.110.10' -or $_.Name -match 'VCSA|vCenter' } |
  Select-Object Name, VMHost, PowerState
((Get-View ServiceInstance).CurrentTime().ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalSeconds + $dMay   # lệch đồng hồ vCenter
```
- VAMI `https://10.189.110.10:5480` → Time: chế độ (Disabled / Host / NTP) và server. Vị trí DC .21 lấy từ 0b.
- VCSA ở chế độ Host và nằm trong Cluster-01 (cả 3 host đều là mục tiêu) → **DỪNG**, xử lý riêng (CR chuyển VCSA sang NTP).
- Đồng hồ vCenter lệch > 60 s → ghi nhận, đưa vào CR tiếp theo; không chặn CR này.

### 0e. Job trong cửa sổ
- vCenter → Recent Tasks, Scheduled Tasks; `Get-Task | Where-Object State -eq 'Running'`. Lịch job backup: phần mềm và lịch [cần xác minh], Đăng xác nhận.
- Mong đợi: không có backup / snapshot / vMotion / Storage vMotion / nâng cấp VMware Tools / reboot VM nào đang chạy hoặc lên lịch trên 3 host trong cửa sổ, vì các sự kiện này kích hoạt đồng bộ giờ một lần. Có → dời cửa sổ (CR này không tắt job backup).

### 0f. Sai số đồng hồ máy Đăng
```bat
w32tm /stripchart /computer:10.179.120.20 /samples:3 /dataonly
```
- Chạy trên chính máy dùng PowerCLI. Offset o = giờ server − giờ máy [cần xác minh dấu: 25/11 máy nhanh ≈ 13 s nên mong đợi o ≈ −13 s]. Điền `$dMay = −o`.
- Không đo được → lấy Δmáy từ host FHN01 .21 đang đồng bộ tốt (cách làm ở [[2026-11-27-ntp-esxi-pcce3-fhn01]] mục 0f, cần thêm phiên vCenter 10.179.110.10), hoặc ghi "chưa đo được ngưỡng 2 s" và đo lại ở bước 4.

### 1.1 / 2.1 / 3.1. Chỉnh giờ tay
```powershell
$h   = Get-VMHost -Name <IP>
$dts = Get-View $h.ExtensionData.ConfigManager.DateTimeSystem
$dts.UpdateDateTime((Get-Date).ToUniversalTime().AddSeconds(-$dMay))   # đặt về giờ chuẩn
Get-HostOffset $h                                                      # mong đợi trị tuyệt đối ≤ 60 s
```
- Lý do làm trước: cả 3 host lệch > 1000 s. ntpd mặc định coi độ lệch > 1000 s là vượt "sanity limit" và không chỉnh [cần xác minh trên ESXi 6.5]. Chỉnh tay trước an toàn trong mọi trường hợp.
- UI tương đương: Time Configuration → Edit → "Manually configure the date and time on this host" → nhập giờ. **Lưu ý:** UI hiển thị theo múi giờ trình duyệt, host lưu UTC. [SL] Nhập nhầm múi giờ có thể chính là nguyên nhân các host lệch khoảng +8 giờ (HC25 §2.2) → verify ngay bằng `Get-HostOffset`.
- [cần xác minh] Trên client 6.5, chọn "Manually configure" có thể tắt NTP client; bước x.2 bật lại.
- Ghi giờ chính xác lúc chỉnh vào "Kết quả thực tế": log vmkernel / hostd sẽ có bước nhảy tại thời điểm này (cần khi đọc log cho RCA sau).

### 1.2 / 2.2 / 3.2. Cấu hình NTP
```powershell
$h = Get-VMHost -Name <IP>
Remove-VMHostNtpServer -VMHost $h -NtpServer 10.189.120.20 -Confirm:$false   # .22 / .21, chỉ khi S ≠ .20
Add-VMHostNtpServer    -VMHost $h -NtpServer $S                              # .22 / .21 chỉ khi S ≠ .20; .25 luôn chạy
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Set-VMHostFirewallException -Enabled $true
$svc = Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd'
Set-VMHostService -HostService $svc -Policy On             # = "Start and stop with host"
Start-VMHostService   -HostService $svc -Confirm:$false    # .22, .25 (đang Stopped)
Restart-VMHostService -HostService $svc -Confirm:$false    # .21 (đang Running). Mỗi host chỉ chạy 1 trong 2 dòng này
```
UI: Edit Time Configuration → "Use Network Time Protocol (Enable NTP client)" → NTP Servers = S → NTP Service Startup Policy "Start and stop with host" → Start (.21: Restart) → OK.

### 1.3 / 2.3 / 3.3 / 4. Verify
```powershell
$h = Get-VMHost -Name <IP>
Get-VMHostNtpServer -VMHost $h                                                              # = S
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Select-Object Enabled           # True
Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd' | Select-Object Running, Policy  # True, on
$h.ConnectionState                                                                          # Connected
$h.ExtensionData.Runtime.DasHostState.State                                                 # master hoặc connectedToMaster
Get-VIEvent -Entity $h -Start (Get-Date).AddMinutes(-30) | Select-Object CreatedTime, FullFormattedMessage
Get-HostOffset $h                                                                           # sau 10–15 phút: trị tuyệt đối ≤ 2 s
```
- UI: NTP Client Enabled, Service Running, đúng server, policy "Start and stop with host"; Triggered Alarms không có alarm mới so với 0a. Events có thể có sự kiện đổi giờ kiểu "system clock stepped" (đã gặp ở SG02 .22, HC25 §3.1): bình thường.
- Bước 4 (sau 24 giờ): chạy khối này cho cả 3 host; xem lần backup đầu tiên sau change có VM nào báo lỗi giờ không; VM nào reboot / bật lại trong 24 giờ thì kiểm tra giờ guest.

### Rollback
- **R-1 (chỉnh giờ tay): không có rollback có nghĩa.** Không đưa host về giờ sai. Đặt nhầm (lệch > 60 s) thì chạy lại bước x.1.
- **R-2 (cấu hình NTP): khôi phục đúng giá trị 0a.** Dùng khi cấu hình mới gây lỗi, hoặc ntpd kéo giờ host xa UTC (lệch > 5 s và tăng dần, tức S sai): chạy R-2, chạy lại x.1 để host không ở giờ sai, rồi DỪNG CR.
```powershell
$h   = Get-VMHost -Name <IP>
$svc = Get-VMHostService -VMHost $h | Where-Object Key -eq 'ntpd'
Stop-VMHostService -HostService $svc -Confirm:$false                  # .22, .25 (0a: Stopped)
Remove-VMHostNtpServer -VMHost $h -NtpServer $S -Confirm:$false        # chỉ khi x.2 đã thêm S
Add-VMHostNtpServer -VMHost $h -NtpServer 10.189.120.20                # .22, .21: chỉ khi x.2 đã gỡ .120.20
Get-VMHostFirewallException -VMHost $h -Name "NTP Client" | Set-VMHostFirewallException -Enabled $false   # .21, .25 (0a: Disabled)
Set-VMHostService -HostService $svc -Policy <Off / On / Automatic theo 0a>
Restart-VMHostService -HostService $svc -Confirm:$false                # .21 (0a: Running)
```
  UI: Edit Time Configuration → đặt lại đúng như ảnh chụp 0a.
- **R-G (guest bị nhảy giờ):** Windows `w32tm /resync /rediscover`; Linux chrony `chronyc makestep`; Linux ntpd `systemctl restart ntpd` (nếu chạy với `-g`) hoặc dừng ntpd, `ntpdate -u <server>`, rồi start lại. Thao tác nặng hơn (restart service ứng dụng, failover) chỉ qua CR mới.

### Điều kiện dừng (không sang host kế tiếp)
- Host Disconnected / Not responding. Nếu tự Connected lại trong ≤ 5 phút: ghi nhận, hỏi Đăng trước khi đi tiếp.
- Lỗi HA agent, hoặc DasHostState khác master / connectedToMaster.
- Alarm mới trên host hoặc VM so với baseline 0a.
- Guest báo lỗi giờ (Kerberos, TLS, ứng dụng) qua giám sát hoặc người dùng.
- Sau 30 phút lệch vẫn > 2 s: giữ nguyên trạng thái (giờ đã chỉnh tay vẫn tốt hơn hiện trạng), báo Đăng. [SL] Nghi UDP 123 bị chặn giữa VLAN 110 (MGT) và VLAN 120 (SYS).
- Một bước lỗi: thử lại tối đa 2 lần sau khi đã sửa nguyên nhân (CLAUDE.md §4.9).

## Ngoài phạm vi: CR tiếp theo (không gộp vào CR này)
- FHN01 .22: trỏ nhầm 10.189.120.20 (NTP của SMB), ≈ +7 giờ 58 phút. FHN01 .53: NTP Disabled, ≈ −1 giờ (HC25 §3.4). Cùng vCenter với [[2026-11-27-ntp-esxi-pcce3-fhn01]].
- FPTDC .178 / .188: Disabled, ≈ +7 / −8 phút; site đang có 10.0.3.47, .39 (đang dùng cho .186) [cần xác minh].
- VDC 5 host (.24, .122, .123, .124, .125; .125 ≈ +7 giờ 57 phút): [[2026-11-24-vsphere-health-VDC]]; cần chốt nguồn .120.20 (PDC) hay .120.21 (VM NTP).
- Có điều kiện: sửa nguồn giờ của AD SMB nếu 0b không đạt; chuyển VCSA SMB sang NTP nếu 0d thấy chế độ Host hoặc lệch giờ; thêm nguồn NTP thứ 2–3 cho từng site; ghi "10.189.120.20 là gì" vào [[open-questions]] nếu 0b chưa làm rõ.

## Phê duyệt
- Người duyệt: Đăng
- Thời điểm duyệt:

## Kết quả thực tế
### Pre-check (bước 0)
| Mục | Kết quả (giá trị, giờ đo UTC+7) | Đạt? |
|---|---|---|
| 0a .22: server / firewall / Running / Policy / lệch / alarm | | |
| 0a .21: như trên | | |
| 0a .25: như trên | | |
| 0b offset .120.20 / .120.21 / 10.179.120.20; source và status của DC → **S =** | | |
| 0c VM có SyncTimeWithHost khác False | | |
| 0d VCSA ở host nào, chế độ giờ, lệch đồng hồ vCenter; DC .21 ở host nào | | |
| 0e Task / backup / snapshot / vMotion trong cửa sổ | | |
| 0f Offset o máy Đăng → Δmáy | | |

### Thực thi
| Bước | Thời gian (UTC+7) | Output verify | Ghi chú |
|---|---|---|---|
| 1.1 .22 chỉnh giờ tay | | | |
| 1.2 .22 cấu hình NTP | | | |
| 1.3 .22 verify | | | |
| 2.1 .21 chỉnh giờ tay | | | |
| 2.2 .21 cấu hình NTP | | | |
| 2.3 .21 verify | | | |
| 3.1 .25 chỉnh giờ tay | | | |
| 3.2 .25 cấu hình NTP | | | |
| 3.3 .25 verify | | | |
| 4 Sau 24 giờ | | | |

### Đóng CR
- Trạng thái cuối:
- Việc còn mở:
- Note đã cập nhật: [[FSG02]] (mục NTP), [[risk-register]] R-014
