---
type: system
status: unverified
site: FHN01
customer: VietinBank
group: VTB-CRMv4-DB
updated: 2026-11-25
tags: [system, postgresql, patroni, percona, vietinbank, crm-v4]
---
# VTB CRM v4 — PostgreSQL HA (Percona, rút gọn 3 VM)

Liên quan: [[VietinBank]] · [[FHN01]] · [[2026-11-24-ket-noi-FHN01-FHN02-app-db]] · Brief phương án 2 site (Claude Docs): https://claude.ai/artifact/641DB2hBczxN1ct7YZQAhg
Nguồn thô: `90-Raw/ingested/2026-11-24/webex-CCX-CCE-2026-11-23-Ngan-VTB-CRMv4.md` (chat Webex với Ngân + ảnh Checkmk).

## Tổng quan
| Thuộc tính | Giá trị | Nguồn |
|---|---|---|
| Vai trò | Database PostgreSQL PROD của VietinBank CRM v4 | Ngân, Webex 23/11 |
| Mô hình thiết kế | [Percona PostgreSQL 17 HA reference architecture](https://docs.percona.com/postgresql/17/solutions/ha-architecture.html): 3 PG + Patroni, etcd ≥3, HAProxy ≥2 + keepalived, pgBackRest, (pgBouncer, PMM) → **11 VM** | Ngân gửi link |
| Mô hình đang chạy | **Rút gọn còn 3 VM**, "các dịch vụ cài hết lên 3 VM" (PG + Patroni + etcd + HAProxy… cùng VM). Lãnh đạo ("các sếp") thảo luận và quyết định rút gọn | Ngân, Webex 23/11 |
| Go-live | Tháng 06/2026 | Ngân, Webex 23/11 |
| Node đã biết | `VTB_CRMv4_DB_PG02` 172.31.90.32 — Ngân gọi là **primary** (chưa verify bằng `patronictl list`) | Checkmk + Ngân |
| Node khác | **`VTB_uCRMv4_DB01` 172.31.90.31, `DB02` .32, `DB03` .33**, mỗi node 616 GB, Powered On. Cùng cụm v4 còn có App01 / App02 (.185.70 / .71), Es01 (.185.72), Share01 (.185.73), Report (.90.42, 616 GB), MidDB (.90.34, 300 GB, **Powered Off**). Tổng PROD khoảng 3.4 TB. UAT: 172.31.245.111–114 | [Live] vCenter Duy Tân 2026-11-24 |
| PG version / OS | Chưa xác minh (link tài liệu là PG 17) | — |
| Monitoring | Checkmk: service `Filesystem /`, `pgBackRest_Retention` | Ảnh Checkmk |
| Backup | pgBackRest: full Chủ nhật 04:00, incremental hằng ngày 04:00; bản cũ nhất 15/11 (≈ giữ 2 full) | Ảnh Checkmk |
| Khách hàng / Site | [[VietinBank]] / [[FHN01]] (suy từ dải 172.31.x, cần xác minh) | — |

## Dung lượng (Checkmk PG02, filesystem `/`, ngày 23/11/2026)
| Chỉ số | Giá trị |
|---|---|
| Tổng dung lượng | 595.02 GiB |
| Đã dùng | **452.26 GiB (75.94%)**, còn trống 142.76 GiB |
| Đã dùng 35 ngày trước (19/10) | 401.21 GiB → +51 GiB / 35 ngày ≈ **1.46 GiB/ngày** |
| Checkmk trend | +1.19 GiB/ngày (+0.20%/ngày); time left until disk full: 121 ngày 11 giờ |
| Growth trend 35 ngày | min ≈ 478 MiB/ngày · max 4.37 GiB/ngày · avg ≈ 1.70 GiB/ngày · last 1.48 GiB/ngày |
| Ngưỡng | Warning 476.02 GiB (80%) · Critical ≈ 535.5 GiB (90%) |

Dự báo (tính từ 23/11/2026):
| Mốc | Theo trend Checkmk 1.19 GiB/ngày | Theo thực tế 35 ngày 1.46 GiB/ngày |
|---|---|---|
| Warning 80% | ~13/12/2026 (20 ngày) | ~09/12/2026 (16 ngày) |
| Critical 90% | ~01/02/2027 (70 ngày) | ~19/01/2027 (57 ngày) |
| Đầy 100% | ~23/03/2027 (120 ngày) | ~01/03/2027 (98 ngày) |

pgBackRest_Retention (ảnh chữ nhỏ, số **gần đúng**): OK; latest `20261122-040000F_20261123-040000I` (incr), duration ≈ 14m; database size ≈ 427 GB; backup size của bản incr ≈ 23 GB; oldest `20261115-040001F`; "backups policy checks ok".

## Rủi ro đã biết
- Data PostgreSQL nằm trên filesystem `/`: đầy disk thì cả OS, WAL và log cùng chết. Sắp chạm warning (giữa 12/2026).
- 3 VM gánh toàn bộ thành phần của mô hình 11 VM: mất 1 VM là mất đồng thời 1 PG, 1 etcd, 1 HAProxy.
- Vị trí repo pgBackRest chưa rõ; nếu cùng site thì thuộc [[risk-register]] R-008.

## Dùng làm tham chiếu sizing
- Là số liệu thực tế duy nhất hiện có để sizing VTB **uCRM v5** (DB01 172.31.90.101 hiện chỉ 600 GB). Nếu v5 tăng như v4, cần ~1 TB/node cho 12 tháng. Xem [[2026-11-24-ket-noi-FHN01-FHN02-app-db]].

## Cần xác minh
- ~~IP mâu thuẫn .51–.53 với .32~~ → **Đã giải (live 2026-11-24): cụm DB v4 là .31 / .32 / .33.** Dải .90.51–.53 trong x18 là cụm khác hoặc dữ liệu cũ (cần xác minh nếu còn dùng). **25/11:** đó là cụm uCRM cũ (VTB_uCRM_DB02 .52 tắt, VTB_uCRM_DB05 .55 bật), xem [[2026-11-25-vsphere-health-FSG-FHN]].
- PG02 có đang là primary không (`patronictl list`)? Tên, IP của 2 node còn lại?
- Thành phần cụ thể trên mỗi VM (etcd, HAProxy, keepalived/VIP, pgBouncer, PMM?).
- PG major version, OS, dung lượng `/` của các node khác.
- Repo pgBackRest đặt ở đâu, `repo1-retention-full` là bao nhiêu?
- Lượng WAL sinh ra mỗi ngày (`pg_stat_wal`).

## Lịch sử
- 2026-11-24: tạo note từ chat Webex của Ngân (CCX-CCE, 23/11) và ảnh Checkmk do Đăng gửi (Claude chat).
