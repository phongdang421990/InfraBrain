---
name: app-release
description: Quy trình deploy/upgrade ứng dụng trên Linux (AICC, UCRM, Connect247, web portal Node/Next.js, dịch vụ .NET) — khảo sát read-only, đọc hướng dẫn mọi bản trung gian, staging song song, backup thư mục cũ, giữ config, swap nhanh, verify, rollback. Rút từ CR AICC Heineken 1.0.11 (27/11) và BVBank wp-fe 1.0.15 (26/11).
---

# App release

## 1. Khảo sát (read-only) — ghi bảng "Hiện trạng" vào CR
- Version đang chạy (package.json / DLL date / UI), thư mục cài, dung lượng, disk còn trống.
- systemd unit: `systemctl cat <svc>` — User, ExecStart/ExecStartPre, ProtectSystem, ReadWritePaths, Environment (NODE_ENV…).
- Runtime: version runtime **service dùng** có thể khác runtime mặc định của shell (vd Node v20 trong shell, service dùng v22) → luôn export PATH đúng runtime của service.
- Config giữ lại: `.env`, `appsettings*.json`; so `.env.example`/config mẫu bản mới để tìm key mới.
- Công cụ trên máy: psql, pg_dump, rsync, tar, npm… thiếu gì thì đổi cách (tar thay rsync; chạy DB trên máy DB).
- Lock file thay đổi (`package-lock.json`) → `npm ci`, không `npm install`.
- Lỗi có sẵn trước deploy: ghi lại (log + thời gian) để không nhầm là lỗi của bản mới.

## 2. Tài liệu và phạm vi
- Đọc release note + hướng dẫn nâng cấp của **từng bản trung gian** (vd 1.0.8 → 1.0.9 → 1.0.10 → 1.0.11).
- Lập bảng: bước | bản | bắt buộc? | trong phạm vi đã chốt? Bước ngoài phạm vi → hỏi lại người chốt, không tự làm.
- Kiểm tra file mẫu tải từ Drive (unit, conf) trước khi dùng: có thể bị cụt/sai quoting.
- Gói: ghi tên, kích thước, sha256; kiểm tra hash trên server.

## 3. Thực hiện (theo change-request với production)
1. Staging: giải nén vào `/…/release/<version>/` hoặc thư mục tạm; copy config cũ vào; build song song khi bản cũ vẫn chạy.
2. Backup: `cp -a` hoặc `mv` thư mục cũ sang `<dir>.bk<version>` / `/…/backup/<svc>-<version>-<TS>`; không xóa.
3. Unit: không sửa file gốc — dùng drop-in `/etc/systemd/system/<svc>.service.d/NN-<ly-do>.conf`, rồi `daemon-reload`, `systemd-analyze verify`.
4. DB (migration, index): chuyển `db-keeper` / skill `postgres-ops`; thứ tự theo hướng dẫn (thường: stop app → migrate → deploy → start).
5. Swap: stop → mv/chép đè (loại trừ file config) → `chown` đúng user service → start. Ghi thời điểm stop/start để tính downtime.
6. Tar gói đóng trên macOS: thêm `--warning=no-unknown-keyword` (cảnh báo LIBARCHIVE.xattr vô hại).

## 4. Verify
- `systemctl is-active`, `journalctl -u <svc> -n 50 --no-pager`, port lắng nghe, curl health/basePath (200/307 chấp nhận được tùy app).
- UI hiện đúng version; chức năng mới của release hoạt động.
- Log: chỉ tính lỗi **sau** thời điểm start (lọc theo thời gian / mtime file log).
- Ứng dụng voice (AICC/FreeSWITCH): `sofia status`, profile RUNNING, module mới `module_exists`.

## 5. Rollback (viết trước khi làm)
- App: stop → khôi phục thư mục backup → bỏ drop-in → daemon-reload → start.
- DB: migration thường **không có script hạ** → chỉ lùi bằng backup DB. Nếu không dump trước nâng cấp, phải ghi rõ trong CR và xác minh backup tự động hằng đêm.

## 6. Ghi lại
- CR `50-Changes/YYYY-MM-DD-<khach>-<app>-<version>.md` (Hiện trạng, Các bước, Kết quả thực tế, Việc còn mở, Rollback).
- Note hệ thống `10-Systems/` cập nhật version, đường dẫn, unit, runtime.
- Lần đầu với ứng dụng → tạo `60-Runbooks/<app>-upgrade.md` từ CR này.
- Việc ngoài phạm vi (CI hỏng, dọn backup sau nghiệm thu…) → "Việc còn mở".
