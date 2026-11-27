---
type: change
status: done   # draft | approved | done | rolled-back | cancelled
risk: Thấp
window: Bất kỳ lúc nào (chỉ là thao tác file local, không chạm hệ thống production)
systems: [InfraBrain vault]
customer:
updated: 2026-11-24
tags: [change, security, secrets, vault]
---
# CR 2026-11-24: Chuyển sổ mật khẩu/credential ra khỏi vault và bổ sung .gitignore

## Mục tiêu và lý do
- 12 file trong `00-Inbox/Base/` chứa password, enable secret, PSK/ENC, license key, credential của RemoteGW, SAN và DB ở dạng plaintext. Nguồn: kết quả quét có che secret ngày 2026-11-24, xem §1.3 của [[BaseBS-Infra-Master-Overview]].
- Làm như vậy trái CLAUDE.md §4.3 ("không ghi secret vào vault").
- File `.gitignore` hiện tại không loại trừ `00-Inbox/`. Nếu sau này vault được `git init` và push lên, toàn bộ các file này sẽ bị commit theo.
- Bản "remove pasword" thực ra **chưa sạch**: vẫn còn enable secret nằm trong ô header.

## Phạm vi ảnh hưởng
- Hệ thống: chỉ vault InfraBrain (local). Không thiết bị hay hệ thống production nào bị chạm tới.
- Gián đoạn: Không.
- Ảnh hưởng phụ:
  - Các note mới (Master Overview, note site/khách hàng) có trích tên các file này làm nguồn. Tên file giữ nguyên, chỉ đổi vị trí. Sau CR sẽ bổ sung ghi chú vị trí mới vào §9 Phụ lục nguồn.
  - Claude và agent hiện chỉ đọc bản trích đã che trong scratchpad, nên không bị ảnh hưởng.
- Thông báo cho: không cần.

## Quyết định thiết kế
- **Đích đến là thư mục ngoài vault**: `C:\Users\Dang Tran\Documents\BaseBS-Secrets-Quarantine\`, giữ nguyên cấu trúc thư mục con.
  - Lý do: nằm ngoài index của Obsidian và ngoài mọi cơ chế sync hay git của vault, đồng thời Claude không truy cập được (sandbox).
  - Phương án thay thế: `99-Secrets/` trong vault. Thư mục này đã có trong `.gitignore` và bị deny-read, nhưng Obsidian vẫn index được.
- **Ai thực hiện:** bước di chuyển do **Đăng tự chạy** (dùng tiền tố `!`), vì sandbox chặn Claude ghi ra ngoài vault. Đây là thiết kế có chủ đích. Claude chỉ verify từ phía vault và sửa `.gitignore`.
- **Ngoài phạm vi CR này (cần CR hoặc việc riêng):**
  - import vào password manager;
  - rotate các credential đã lộ (ưu tiên RemoteGW, enable secret, SAN 10.199.110.9);
  - xóa vĩnh viễn thư mục quarantine;
  - xóa file khóa Office `~$SEBS_INFRA_HANDOVER_NOTES_13-11-2026.md`.

## Danh sách file (hash SHA-256, 16 ký tự đầu, ghi trước khi thực hiện)
| # | File (dưới `00-Inbox/Base/`) | Lý do | SHA-256 (16) |
|---|---|---|---|
| 1 | `Base-Passwork-AllDC.xlsx` | Sổ password đầy đủ | EB51EEAE4AD240C2 |
| 2 | `Base-Passwork-AllDC-remove pasword.xlsx` | Còn enable secret trong header | 5791076CBBEB3C5E |
| 3 | `NoiBo1-Infra-Credential.xlsx` | Cột User/Passwd theo từng site | 6FF6677E15041B83 |
| 4 | `NoiBo1-Infras-System Hardware Credentials.xlsx` | MGMT/VMware password, license key, SAN credential | DE6ECE419D4F005C |
| 5 | `NoiBo1-Infras-System RemoteGW.xlsx` | DB root, Guacamole, LDAP bind (**nghiêm trọng**) | 0A5CC58F24988A01 |
| 6 | `Nội Bộ 2 - Heineken - AICC-NoiBo2 _  Credentials.xlsx` | root/user password VM, portal CMC | 67D1D8EA4BF17F36 |
| 7 | `NoiBo2- System Transfer -Tin.xlsx` | Chuỗi user/password ở R10 | C1492FD0FC6D836A |
| 8 | `FTP Cloud (1).zip` | Chứa FortiGate .conf có ENC password/PSK | 8601444F1AC319C7 |
| 9 | `Infra/Base-Password-DangTP.xlsx` | Sổ password cá nhân | 02E7943F13DE1582 |
| 10 | `Infra/Base-Passwork-System Infra.xlsx` | Giống #4 | 51291D919A1DFA47 |
| 11 | `Infra/NoiBo1-Infra-Credential.xlsx` | Bản mới hơn của #3 | 62B2A002C93FAFC3 |
| 12 | `Keepass Network/VinhLQ-network.kdbx` | Database KeePass (đã mã hóa, nhưng không thuộc về vault) | 47A9C3182CE1ACC4 |

Giữ lại trong vault vì không phát hiện secret: Master Inventory, báo cáo VDC, Infra_Handover, Handover Pack zip, Device Status, VNPT topology, NOTES/BRIEFING, SVG. File `Nội bộ 2 - DevOps-request-network-rules-backup.xlsx` có cột "Login" bị bộ lọc che; chưa xác định đó là secret hay chỉ là trạng thái. **Tạm giữ lại, chờ Đăng xác nhận.**

## Điều kiện tiên quyết
- [x] Đã ghi hash trước khi thực hiện (bảng trên).
- [ ] Đóng Excel/KeePass nếu đang mở các file này.
- [ ] (Khuyến nghị) Ổ đích có BitLocker, hoặc thư mục đích không nằm trong OneDrive/Dropbox sync.
- [ ] Không cần thông báo khách hàng, không cần người standby.

## Các bước thực hiện
| # | Người chạy | Lệnh | Verify (kết quả mong đợi) | Rollback |
|---|---|---|---|---|
| 1 | Đăng | `! pwsh -NoProfile -File "C:\Users\Dang Tran\Documents\InfraBrain\50-Changes\2026-11-24-quarantine-credential-files.Move-CredFiles.ps1"` (nội dung script ở phụ lục A) | Script in ra 12 dòng `MOVED <file> <hash16>`, hash khớp bảng trên, cuối cùng in `OK 12/12` | Cùng lệnh, thêm `-Rollback` ở cuối (chuyển ngược 12 file về vị trí cũ, kiểm tra hash) |
| 2 | Claude | `Get-ChildItem 00-Inbox -Recurse -File -Force` rồi đối chiếu với 12 tên file | Không còn file nào trong 12 file ở `00-Inbox/`; các file "giữ lại" vẫn còn nguyên | Như bước 1 |
| 3 | Claude | Thêm khối loại trừ vào cuối `.gitignore` (phụ lục B) | Các file khác của `.gitignore` không đổi; khối mới xuất hiện đúng 1 lần | Xóa khối mới (nằm giữa 2 dòng marker `# >>> CR 2026-11-24` và `# <<< CR 2026-11-24`) |
| 4 | Claude | Quét lại `00-Inbox/`: tên file khớp `*Pass*`, `*Credential*`, `*.kdbx`, `*.conf` | 0 kết quả | Không áp dụng |
| 5 | Claude | Cập nhật §9 Phụ lục nguồn trong [[BaseBS-Infra-Master-Overview]]: thêm ghi chú "đã chuyển sang quarantine ngoài vault theo CR này". Đóng CR | Ghi chú xuất hiện trong file; CR có `status: done` | Hoàn tác đoạn ghi chú |

### Phụ lục A: `Move-CredFiles.ps1`
Script: `50-Changes/2026-11-24-quarantine-credential-files.Move-CredFiles.ps1`, đặt cạnh CR. **Bản sửa 2026-11-24:** theo yêu cầu của Đăng, script được chuyển từ scratchpad (thư mục tạm, có thể bị dọn) vào vault. Logic, danh sách file, hash và đích đến **không đổi** so với bản đã duyệt; chỉ đổi vị trí lưu script và đường dẫn trong lệnh ở bước 1. Xem toàn văn trước khi chạy. Script chỉ dùng `Move-Item`, kiểm tra hash trước và sau khi chuyển, không xóa gì. Nếu file đích đã tồn tại thì dừng.

### Phụ lục B: khối thêm vào `.gitignore`
```gitignore
# >>> CR 2026-11-24 — sổ mật khẩu / credential / tài liệu thô
00-Inbox/
*Passwork*
*Password*
*password*
*Credential*
*credential*
*.conf
~$*
# <<< CR 2026-11-24
```

## Phê duyệt
- Người duyệt: Đăng (trả lời "Duyệt" trong phiên Claude Code ngay sau khi CR được trình)
- Thời điểm duyệt: 2026-11-24 (UTC+7)

## Kết quả thực tế
Ngày thực hiện: 2026-11-24 (UTC+7). Kết quả chung: **Thành công**, không cần rollback. Có 1 lỗi thiết kế ở bước 3, xem mục "Vấn đề phát sinh".

| # | Kết quả | Bằng chứng |
|---|---|---|
| 1 | ✅ Đăng chạy script trong vault (bản sửa, code giống bản đã duyệt, 0 dòng khác) | Output: 12 dòng `MOVED`, hash sau khi chuyển khớp bảng ở trên 100%, dòng cuối `OK 12/12 -> C:\Users\Dang Tran\Documents\BaseBS-Secrets-Quarantine` |
| 2 | ✅ Quét toàn vault: **0/12** file credential còn lại. 12 file không chứa credential đã chuyển trước đó sang `90-Raw/BaseBS-Handover-2026-11/` vẫn nguyên, **12/12 khớp hash** so với `_move-log-2026-11-24.csv` | `Get-ChildItem -Recurse` + `Get-FileHash` |
| 3 | ✅ Đã thêm khối có marker vào cuối `.gitignore`. Marker mở và đóng mỗi loại 1 lần; dòng 1–15 cũ không đổi | Đọc lại `.gitignore` |
| 4 | ✅ Quét `00-Inbox/` và toàn vault (trừ `.claude/`) với `*Pass*`, `*Password*`, `*Passwork*`, `*Credential*`, `.kdbx`, `.conf`, `.pem`, `.key`: **0 kết quả** | `Get-ChildItem` |
| 5 | ✅ [[BaseBS-Infra-Master-Overview]] đã cập nhật ở rủi ro #7 (§1.2), phần trạng thái chung §1.3, dòng FPT Cloud config và ghi chú §9 về vị trí mới | Edit |

### Trạng thái sau change
- `00-Inbox/` còn `_README.md`, 2 thư mục rỗng (`Base/Infra`, `Base/Keepass Network`) và file khóa Office `Base/~$SEBS_INFRA_HANDOVER_NOTES_13-11-2026.md`. Xóa các mục này **nằm ngoài CR**, chờ Đăng quyết.
- Script vẫn ở `50-Changes/` để dùng cho rollback (`-Rollback`) khi cần.

### Vấn đề phát sinh
- **Bước 3, mẫu `*credential*` chặn nhầm chính CR này.** File `2026-11-24-quarantine-credential-files.md` và `.Move-CredFiles.ps1` khớp mẫu nên sẽ không được commit nếu sau này `git init`.
  - Hiện vault chưa phải git repo và máy chưa cài git, nên **chưa có ảnh hưởng**, và cũng **không test được** bằng `git check-ignore`. Phần kiểm tra đã làm là đối chiếu tay mẫu với tên file.
  - Cách xử lý đề xuất (cần duyệt riêng, xem bên dưới): thêm 2 dòng ngoại lệ vào trong khối CR:
    ```gitignore
    !50-Changes/2026-11-24-quarantine-credential-files.md
    !50-Changes/2026-11-24-quarantine-credential-files.Move-CredFiles.ps1
    ```
    Rollback: xóa 2 dòng đó. Verify: không file nào ngoài `00-Inbox/`, `90-Raw/` khớp mẫu mà không có ngoại lệ.
  - **✅ Đã xử lý 2026-11-24.** Đăng duyệt riêng ("DUYỆT sửa gitignore").
    - Đã thêm 2 dòng ngoại lệ (kèm comment) vào trong khối CR, trước marker đóng. Khối nằm ở dòng 17–29 của `.gitignore`.
    - Verify bằng mô phỏng logic, vì máy chưa có git để chạy `git check-ignore`:
      - chỉ 2 file ngoài `00-Inbox/`, `90-Raw/`, `.claude/` khớp mẫu, và cả 2 được ngoại lệ đưa về **tracked**;
      - đường dẫn ngoại lệ trỏ đúng file đang tồn tại;
      - thư mục cha `50-Changes/` không bị ignore, nên ngoại lệ có hiệu lực.
    - Khi đã cài git, chạy lại `git check-ignore -v` để xác nhận.

### Việc tiếp theo (ngoài CR)
1. ✅ *Đăng xác nhận đã xong 2026-11-24 (Claude chưa verify).* **Rotate credential đã lộ** (ưu tiên cao): RemoteGW (DB root / Guacamole / LDAP bind), enable secret trong file Passwork, SAN 10.199.110.9, VMware license key (xem xét), cùng 6 tài khoản SSO vCenter và tài khoản connect247.vn mà Đăng đã dán vào chat ngày 2026-11-24. Các password này nằm trong transcript Claude Code ở `~/.claude/projects/…InfraBrain/*.jsonl`.
2. Import các sổ đang ở quarantine vào password manager, sau đó xóa thư mục quarantine (cần CR riêng).
3. Quyết định xóa 2 thư mục rỗng, file khóa Office và bản trùng `…__trung.xlsx` trong `90-Raw`.
