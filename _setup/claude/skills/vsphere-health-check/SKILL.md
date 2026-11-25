---
name: vsphere-health-check
description: Health check read-only cho VMware vCenter/ESXi (host, cluster HA/DRS, datastore, snapshot cũ, VMware Tools, triggered alarms) bằng PowerCLI, rồi phân tích CSV thành báo cáo đỏ/vàng/xanh. Dùng khi kiểm tra sức khỏe vSphere định kỳ hoặc trước/sau change.
---

# vSphere health check

## Bước 1 — Thu thập (chủ vault chạy hoặc agent chạy trên máy có quyền vào vCenter)
```powershell
# Một lần: Install-Module VMware.PowerCLI -Scope CurrentUser
# Nếu vCenter dùng cert self-signed (chỉ trong mạng quản trị):
# Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope User -Confirm:$false
.\.claude\skills\vsphere-health-check\scripts\Invoke-VSphereHealthCheck.ps1 -VCenter <fqdn-hoac-ip>
```
- Script hỏi credential qua `Get-Credential` — dùng **tài khoản có role Read-only**. Không lưu mật khẩu.
- Kết quả: `90-Raw/healthcheck/<vcenter>_<thoi-gian>/*.csv`.

## Bước 2 — Phân tích
Đọc các CSV và áp ngưỡng:
| Hạng mục | 🔴 Critical | 🟡 Warning |
|---|---|---|
| Host | ConnectionState ≠ Connected, OverallStatus = red | OverallStatus = yellow, uptime > 365 ngày (thiếu patch), ESXi 5.5/6.x (EOL) |
| Cluster | HAEnabled = False | AdmissionControl tắt, DRS tắt/manual |
| Datastore | UsedPct ≥ 90, Accessible = False | UsedPct ≥ 80 |
| Snapshot | > 30 ngày hoặc > 100 GB | > 7 ngày |
| VM | OverallStatus = red | Tools không chạy trên VM đang bật |
| Alarm | OverallStatus = red, chưa ack | yellow |
| Capacity | Cluster không còn đủ tài nguyên khi mất 1 host (N+1) | CPU/RAM host > 80% |

Với N+1: cộng RAM đã dùng của cả cluster, so với tổng RAM trừ host lớn nhất.

## Bước 3 — Báo cáo
Ghi `80-Reports/health-check/YYYY-MM-DD-<vcenter>.md`:
1. Tóm tắt 3 dòng cho quản lý (số lỗi đỏ/vàng, rủi ro lớn nhất).
2. Bảng phát hiện: mức độ, đối tượng, mô tả, ảnh hưởng dịch vụ (link `[[note hệ thống]]`), đề xuất.
3. So sánh với lần trước: mới / đã xử lý / tồn đọng.
4. Cập nhật `80-Reports/risk-register.md` với rủi ro mới.
