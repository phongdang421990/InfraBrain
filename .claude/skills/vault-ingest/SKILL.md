---
name: vault-ingest
description: Nạp tài liệu thô (Excel/CSV bàn giao, Word, PDF, email, ghi chú, config export) từ 00-Inbox vào vault thành note có cấu trúc — hệ thống, site, khách hàng — có wikilink, nguồn, và danh sách câu hỏi cần xác minh. Dùng khi thả tài liệu mới vào vault hoặc muốn "dạy" Claude về hệ thống.
---

# Vault ingest

## Quy trình
1. Liệt kê file trong `00-Inbox/`; đọc từng file (Excel/CSV: đọc toàn bộ sheet, ghi lại tên cột).
2. Trích thực thể:
   - Hệ thống/thiết bị: hostname, IP quản trị, vai trò, OS/firmware, site, rack, khách hàng, owner
   - Kết nối: link, VLAN, VPN, MetroNet, inbound mapping
   - Phụ thuộc: dịch vụ A cần B (DNS, AD, DB, cert)
3. Với mỗi thực thể:
   - Đã có note → cập nhật, giữ lịch sử ("trước đây: ...").
   - Chưa có → tạo từ `Templates/System.md` (hoặc Site/Customer).
4. Mâu thuẫn giữa nguồn → ghi cả hai giá trị và nguồn vào mục "Cần xác minh", thêm vào `80-Reports/open-questions.md`.
5. Che mọi secret trước khi ghi (password, PSK, community, token).
6. Chuyển file gốc sang `90-Raw/ingested/YYYY-MM-DD/`.
7. Báo lại: số note tạo mới/cập nhật, số mâu thuẫn, 5 câu hỏi quan trọng nhất cần Đăng trả lời.

## Đặt tên note
- Hệ thống: `10-Systems/<site>-<hostname>.md` (vd `FDC-PCCE1-RGR-A.md`)
- Nhóm hệ thống: `10-Systems/_<nhom>.md` (MOC liệt kê các note thành viên)
- Site: `20-Sites/<site>.md`; Khách hàng: `30-Customers/<ten>.md`
