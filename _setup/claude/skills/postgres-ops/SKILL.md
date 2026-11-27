---
name: postgres-ops
description: Thao tác PostgreSQL an toàn — khảo sát (version, vai trò node, owner, extension, backup), chạy migration của hãng, tạo index trên bảng lớn, sửa owner, kiểm tra HA (Patroni/Percona) và backup/restore. Rút từ CR AICC Heineken 1.0.11 (27/11) và đánh giá VTB uCRM HA.
---

# PostgreSQL ops

## 1. Khảo sát (read-only)
```bash
psql -V; sudo -u postgres psql -Atc "select version();"
sudo -u postgres psql -Atc "select pg_is_in_recovery();"          # t = replica
sudo -u postgres psql -c "\l+"                                     # DB, owner, size
sudo -u postgres psql -d <db> -c "\dx"                             # extension
sudo -u postgres psql -d <db> -Atc "select schemaname,tablename,tableowner from pg_tables where schemaname='public' and tableowner<>'<app_user>';"
```
- HA: `patronictl -c <cfg> list` (leader/replica, lag, timeline); Percona/repmgr tương ứng.
- Backup: job nào (pg_dump/pgBackRest/pg_basebackup/snapshot), lịch, lần chạy gần nhất, nơi lưu (cùng site hay off-site), **lần restore thử gần nhất**.
- Đăng nhập: nếu app user cần mật khẩu qua TCP còn `postgres` dùng peer → chạy bằng `su - postgres` + `PGOPTIONS='-c role=<app_user>'` để object mới thuộc app user, không cần nhập mật khẩu.

## 2. Migration của hãng
- Thứ tự theo hướng dẫn từng bản; mỗi file:
  `psql -d <db> --single-transaction -P pager=off -v ON_ERROR_STOP=1 -f <file>.sql`
- Trước khi chạy: liệt kê bảng không thuộc app user (lệnh ở §1). Lỗi `must be owner of table …` → transaction tự rollback; `ALTER TABLE … OWNER TO <app_user>` cho đúng các bảng đó (qua change-request), rồi chạy lại.
- Ghi số lệnh `completed` / NOTICE của từng file vào CR, so với tài liệu.

## 3. Index trên bảng lớn
- `CREATE EXTENSION IF NOT EXISTS pg_trgm;` (nếu là GIN trigram)
- `CREATE INDEX CONCURRENTLY IF NOT EXISTS …` (không chạy trong transaction block).
- Verify: `select indexrelid::regclass, indisvalid from pg_index where not indisvalid;` → phải rỗng; index lỗi thì `DROP INDEX CONCURRENTLY` rồi tạo lại.

## 4. HA 2 site (đánh giá)
- Ước lượng WAL/giờ (`pg_stat_wal` hoặc chênh lệch `pg_current_wal_lsn()` theo thời gian) so với băng thông link liên site.
- Synchronous commit qua WAN: đo RTT; cân nhắc `synchronous_commit=remote_write` hoặc async + chấp nhận RPO.
- Quorum (etcd/witness) đặt ở site thứ 3 hoặc site có app; tránh 2 node + 2 node chia đều.
- Sau thay đổi: diễn tập switchover có kế hoạch, ghi thời gian gián đoạn.

## 5. Backup và restore
- "Có backup" chưa đủ: restore thử vào máy/instance tạm, ghi thời gian, kích thước, kiểm tra số bản ghi bảng chính.
- Trước nâng cấp có migration: khuyến nghị `pg_dump -Fc` riêng; nếu Đăng quyết không dump → ghi rõ trong CR, xác minh backup tự động gần nhất trước khi bắt đầu.

## 6. Ghi lại
- Note DB `10-Systems/_<he-thong>-DB.md`: version, node, owner, extension, backup, HA.
- Thiếu backup off-site / chưa test restore → cập nhật `risk-register` (R-008).
