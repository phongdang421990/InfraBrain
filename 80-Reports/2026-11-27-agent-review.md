---
type: report
status: approved
updated: 2026-11-27
tags: [report, agents, review]
---
# Review đội agent và phân bổ công việc: 2026-11-27

Nguồn: toàn bộ vault (50-Changes, 40-Incidents, 70-Designs, 80-Reports, 10-Systems, 95-Agent-Logs) và các chủ đề chủ vault đã trao đổi với Claude.

## 1. Công việc đang handle

### BaseBS
| # | Công việc | Trạng thái | Agent đang/nên handle | Note chính |
|---|---|---|---|---|
| B1 | Tiếp nhận hạ tầng 5 DC: Master Overview, CMDB, phụ lục IP | Review | doc-scribe | [[BaseBS-Infra-Master-Overview]] |
| B2 | 42 câu hỏi mở / mâu thuẫn nguồn | Đang mở | doc-scribe + net-warden + infra-sentinel | [[open-questions]] |
| B3 | Risk register (35 rủi ro: FW EOL, cert, storage, ESXi cũ, backup cùng site…) | Đang mở | infra-sentinel | [[risk-register]] |
| B4 | Health check vSphere VDC (24/11), FSG/FHN (25/11) | Xong | infra-sentinel | [[2026-11-24-vsphere-health-VDC]], [[2026-11-25-vsphere-health-FSG-FHN]] |
| B5 | Sự cố FPTDC 11/11: host .186 mất LUN, 5 CTI tắt | Đang điều tra (A01–A17) | rca-tracer | [[2026-11-11-FPTDC-host186-LUN-loss]] |
| B6 | Cách ly sổ credential khỏi vault; **rotate credential (R-007)** | CR xong; rotate chưa làm | net-warden (security) | [[2026-11-24-quarantine-credential-files]] |
| B7 | VTB uCRM v5 HA 2 site (App HA + Patroni), kết nối FHN01↔FHN02, MetroNet | Draft | si-architect (+ net-warden) | [[2026-11-24-danh-gia-trien-khai-ucrm-v5-HA]], [[2026-11-24-ket-noi-FHN01-FHN02-app-db]] |
| B8 | Chuyển toàn bộ VTB từ Duy Tân sang PVB: roadmap, họp liên team | Mới khởi động | si-architect (thiếu vai trò PM) | — |
| B9 | VTB CRM v4 PostgreSQL (Percona, 3 VM): tài liệu hệ thống | Chưa xác minh | doc-scribe (thiếu vai trò DB) | [[_VTB-CRMv4-DB]] |
| B10 | Network rules request VTB uCRM v4.1 PROD (20/11); đánh giá storage uCRM v5 vCenter HN02 | Còn trong 00-Inbox, chưa nạp | net-warden; si-architect | 00-Inbox |
| B11 | Nâng cấp AICC Heineken 1.0.8 → 1.0.11 | Xong; còn media_timeout, quyền LCM, verify backup DB | cc-echo (lệch vai: thực chất là app Linux + FreeSWITCH + PostgreSQL) | [[2026-11-27-hnk-aicc-1.0.11-upgrade]] |
| B12 | Deploy BVBank web portal FE 1.0.15 lên labtest; GitLab CI hỏng | Xong; CI chưa sửa | **Không có agent phù hợp** | [[2026-11-26-wp-fe-1.0.15-labtest]], [[BVB-WebPortal-FE]] |
| B13 | Tuyển kỹ sư SI (phỏng vấn) | Đang làm | **Không có agent** | — |

### DongJin (DJS)
| # | Công việc | Trạng thái | Agent | Ghi chú |
|---|---|---|---|---|
| D1 | Quản lý mail DJS: Microsoft 365 / Exchange Online | Vận hành | **Không có agent** | Vault chưa có note nào |
| D2 | DJ-Website: VSCode, Cloudflare Workers (`D:\DJ\DJ-Website`) | Đang phát triển | **Không có agent** | Là dự án code, không thuộc vault infra |

### Chưa phân loại
| # | Công việc | Ghi chú |
|---|---|---|
| X1 | `00-Inbox/pc-health/Get-PCHealth.ps1`: health check PC Windows | Chưa rõ thuộc BaseBS hay DJS / cá nhân |

## 2. Tải của từng agent hiện tại
| Agent | Task thực tế đã/đang làm | Nhận xét |
|---|---|---|
| infra-sentinel | B3, B4 | Đúng vai |
| rca-tracer | B5 | Đúng vai; còn 17 action chưa đóng |
| net-warden | B2 (phần mạng), B6, B7 (MetroNet), B10 | Đúng vai; đang ôm thêm security/credential |
| cc-echo | B11 | **Lệch vai**: AICC không phải Cisco PCCE |
| si-architect | B7, B8, B10 | Quá tải: vừa thiết kế vừa lập roadmap, vừa lo DB |
| doc-scribe | B1, B2, B9 | Đúng vai |

Nhật ký: `95-Agent-Logs` mới có từ 27/11, nên chỉ `cc-echo` có dòng nhật ký; các task trước đó chưa được ghi vào nhật ký.

## 3. Đề xuất (chờ chủ vault quyết)
| Ưu tiên | Đề xuất | Lý do | Nhận task |
|---|---|---|---|
| P1 | **Thêm `app-ops`**: deploy/upgrade ứng dụng trên Linux (AICC, UCRM, Web portal, Connect247), systemd, Node/.NET, Nginx, GitLab CI | B11, B12 lặp lại theo cùng một khuôn CR; hiện không có agent đúng vai | B11, B12, các release sau |
| P1 | **Thêm `db-keeper`**: PostgreSQL / SQL Server: HA (Patroni/Percona), migration, backup và verify restore, index, capacity | DB xuất hiện ở B7, B9, B11; hiện bị chia giữa si-architect, cc-echo, doc-scribe | B9, phần DB của B7/B11, R-008 backup |
| P1 | **Tách DongJin ra khỏi vault BaseBS**: vault hoặc thư mục riêng, kèm agent `djs-it` (M365/Exchange Online/Entra ID, mạng văn phòng, website) | Hai công ty khác nhau: tách dữ liệu, tách quy tắc, không lẫn khách hàng ngân hàng với DJS | D1, D2 |
| P2 | **Thêm `pm-planner`**: roadmap, kế hoạch migration, biên bản họp, báo cáo cho anh Phong, tuyển dụng (JD, câu hỏi phỏng vấn, chấm điểm) | B8, B13 là việc quản lý, không phải kỹ thuật | B8, B13, báo cáo tuần |
| P2 | Thu hẹp `cc-echo` về đúng Cisco PCCE/CUCM/CVP/Finesse/CUIC, Avaya | Sau khi có app-ops | — |
| P3 | Cân nhắc tách `sec-guard` khỏi net-warden (credential rotation, cert, MFA VPN, audit) khi khối việc security tăng | Hiện net-warden vẫn kham được | B6, R-007, R-009 |

Việc kèm theo nếu duyệt: tạo file agent trong `_setup/claude/agents/`, chạy lại `Install-AgentTeam.ps1`, cập nhật bảng routing trong `CLAUDE.md` và skill `infrabrain-dispatch`, ghi bù nhật ký cho các task B1–B12.

## 4. Quyết định (2026-11-27)
- Chủ vault **DUYỆT**. Đã áp dụng P1, P2: thêm `app-ops` (skill `app-release`), `db-keeper` (skill `postgres-ops`), `pm-planner`; thu hẹp `cc-echo`; bổ sung phần phối hợp cho `si-architect`; bảng routing mới trong `CLAUDE.md`; ghi bù nhật ký B1–B12; khung vault `_setup/DJBrain-template`.
- P3 (`sec-guard`) chưa tạo — theo điều kiện của chính đề xuất (khi khối việc security tăng).
- Còn chờ chủ vault: chạy lại `Install-AgentTeam.ps1`; chuyển `DJBrain-template` ra `Documents\DJBrain`; lưu bản cập nhật skill `infrabrain-dispatch`.
