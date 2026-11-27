---
type: system
status: verified
updated: 2026-11-26
tags: [system, bvbank, webportal, nextjs, labtest]
---
# BVBank Web Portal FE (wp-fe)

Web portal khách hàng [[BVBank]] (Ngân hàng Bản Việt): trang portal + trang admin, cùng một source Next.js, build 2 lần với `.env` khác nhau.

## Source / CI
- GitLab `crm/webportal/bvb/wp-fe` (project ID 847). Version lấy từ dòng đầu `CHANGELOG.md`.
- CI include `crm/webportal/bvb/template-cicd` ref `Release.v1`: nhánh `Develop` → env `bvb-dev` (runner `portal_bvb_dev`, host `webportal`, `/portal-bvb/...`, service `feportal-bvb`); `Unit-Test`/`main` → env `bvb-test` (runner `portal_bvb_test`, `/portal/...`, service `feportal`). Template được Ngân sửa đường dẫn npm ngày 2026-11-26.
- `.env` lấy từ repo config (`feportal-config`, `feportal-admin-config`) theo nhánh env.

## Labtest = webportal-TEST (172.23.90.197, RHEL 8.10, [[FSG02]] LAB-Test)
| Service | Thư mục | Port | basePath | Public |
|---|---|---|---|---|
| `feportal.service` | `/portal/feportal` | 8001 | `/bvbank-portal` | `https://test.basebs.cloud/bvbank-portal` |
| `feportal-admin.service` | `/portal/feportal-admin` | 8003 | `/bvbank-setting` | `https://test.basebs.cloud/bvbank-setting` |
- Chạy root, Node `/usr/local/node-v22.23.2-linux-x64` (shell mặc định là v20.9.0 — build phải đổi PATH), `node server.js` HTTPS với `/cert/prod.crt|key`.
- BE: `test.basebs.cloud/bvbank-portal/portal-api`, `.../bvbank-setting/api`. Cấu hình nội dung đọc từ CRM (tenant + object `obj_configuration_bvb_portal_01`).
- Đăng nhập: user thường có sudo (không SSH root). Nguồn: Đăng xác nhận 2026-11-26.
- Bằng chứng labtest = máy này: Kha báo "up xong check labtest" 12/11 15:25 trùng giờ start `feportal`.

## Lịch sử deploy
- 2026-11-12: 1.0.14 (Kha, deploy tay, gói `wp-fe-v1.0.14-12112026.tar.gz` trên SharePoint ĐTT.CSKH-Dự án › Base upload).
- 2026-11-26: 1.0.15 (Đăng, deploy tay) — [[2026-11-26-wp-fe-1.0.15-labtest]]. Quy trình: build ở `/portal/release/<ver>/`, swap bằng `mv`, bản cũ giữ ở `/portal/backup/`.

## Cần xác minh
- Runner `portal_bvb_test` có nằm trên webportal-TEST không (nếu có, deploy labtest qua nhánh `Unit-Test`).
- Host `webportal` (DEV) có IP gì.
