---
type: runbook
status: active
updated: 2026-11-28
tags: [runbook, mremoteng, ssh, rdp, inventory]
---
# Import danh sách kết nối BaseBS vào mRemoteNG

## Nội dung thư mục
| File | Ý nghĩa |
|---|---|
| `BaseBS-mRemoteNG-import.csv` | 190 kết nối (175 SSH, 15 RDP), chia theo site và nhóm thiết bị. **Không có user/mật khẩu.** |
| `Fill-mRemoteNG-Credentials.ps1` | Chạy trên máy Đăng: điền user/mật khẩu từ file credential CSV vào file import. File kết quả được ghi **ngoài vault**. |
| `gen.py` | Script sinh lại file CSV khi inventory thay đổi. Danh sách thiết bị nằm ngay trong script. |

Nguồn dữ liệu: [[BaseBS-Infra-Master-Overview-Appendix-IP]], cùng các hệ thống đã xác minh trong CR/note (AICC Heineken, wp-fe, VTB CRM v4 DB). Cột Description giữ nhãn độ tin cậy `[2N]/[1N]/[SL]/[Live]` và mã mâu thuẫn K.., nên khi kết nối lỗi thì xem Description trước.

Cấu trúc cây: `BaseBS > <site> > Network / Firewall / Voice / Storage / vSphere / App / Windows`.
Site: VDC, FSG01, FSG02, LAB-UAT, FHN01, FHN02, CMC-Heineken, FPT-Cloud-POC, SG03, Office-REE.

## Không đưa vào file
- BMC (iDRAC/CIMC): chỉ quản trị qua web.
- IP public/NAT, SVI/gateway, loopback/VIP, pool VPN.
- Thiết bị đã gỡ theo DeviceList 2023 (PCCE01/02, CCX02 ở FHN01).

## Cách dùng
1. **Chuẩn bị file credential CSV** (nằm ngoài vault, ví dụ `C:\Temp\creds.csv`):
   - Từ KeePass: *File > Export > KeePass CSV (1.x)*. Trường *URL/Web Site* phải chứa IP.
   - Hoặc từ sổ Excel: giữ 3 cột **IP ; Username ; Password** (thêm cột Domain nếu cần), rồi *Save As > CSV*.
2. **Chạy script** (PowerShell, trong thư mục này):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Fill-mRemoteNG-Credentials.ps1 -Connections .\BaseBS-mRemoteNG-import.csv -Credentials C:\Temp\creds.csv
   ```
   Script báo số kết nối đã điền và danh sách IP chưa có credential. Script không in mật khẩu ra màn hình.
3. **Import vào mRemoteNG:** *File > Import > Import from File...*, chọn file `Documents\BaseBS-Secrets-Quarantine\BaseBS-mRemoteNG-with-creds.csv`.
4. **Bảo vệ ngay sau khi import:**
   - mRemoteNG: *Tools > Options > Security*, đặt **master password** (mã hóa connection file). Nếu không đặt, mật khẩu chỉ được mã hóa bằng khóa mặc định, ai có file `confCons.xml` cũng giải mã được.
   - **Xóa** `creds.csv` và `BaseBS-mRemoteNG-with-creds.csv`.
5. SSH bằng key: các kết nối SSH dùng PuTTY session *Default Settings*. Nếu Pageant đang chạy và đã nạp key thì không cần mật khẩu.

## Nếu import lỗi định dạng
Các phiên bản mRemoteNG khác nhau có thể đọc CSV khác nhau. Cách xử lý: trong mRemoteNG chọn *File > Export to File...* với định dạng *mRemoteNG CSV* cho 1 kết nối bất kỳ, gửi **dòng tiêu đề** (dòng đầu) cho Claude để sửa `gen.py` cho khớp.

## Lưu ý vận hành
- Nhiều thiết bị chỉ có 1 nguồn `[1N]` hoặc đang có mâu thuẫn K.. Kết nối thất bại là dữ liệu để cập nhật [[open-questions]], không phải lỗi của file.
- ESXi thường tắt SSH mặc định. Unity/VNXe cần bật SSH service trên storage.
- Các App VM ghi "OS chưa xác minh": nếu là Windows, đổi Protocol sang RDP trong mRemoteNG.
