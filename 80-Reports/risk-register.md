---
type: risk-register
updated: 2026-11-24
tags: [risk]
---
# Risk register

Các nhóm rủi ro đã nêu trong quá trình tiếp nhận. Bằng chứng gắn ngày 2026-11-24 lấy từ [[BaseBS-Infra-Master-Overview]] (mã nguồn x01…x24 giải thích ở §9 của báo cáo đó).

| ID | Rủi ro | Hệ thống | Khả năng | Ảnh hưởng | Mức | Xử lý đề xuất | Owner | Trạng thái |
|---|---|---|---|---|---|---|---|---|
| R-001 | Firewall HA chưa đảm bảo | [[FSG02]] FG (có thể chỉ 1 thiết bị vật lý, x13 / BG); [[VDC-VNPT]] FW02 port WAN notconnect (x06); toàn bộ 8 FW hết subscription, FortiOS 5.6.6 / PAN-OS 7.0 (x21) | Cao | Cao | Cao | Lấy `get system ha status` từng site; lập lộ trình thay / gia hạn license | | Mở |
| R-002 | Certificate sắp/đã hết hạn | ESXi 10.169.110.123 hết hạn 31/10/2026 (x06); cert vCenter 10.0.3.50 cần kiểm tra (x01 A14) | Đã xảy ra | TB | Cao | Renew theo quy trình VMware qua change-request | | Mở |
| R-003 | Lỗi / cảnh báo Storage Disk | Unity300 [[FHN01]] (slot 12 chưa có đĩa thay, x14); Unity380 VDC Datastore1 84% (x06); QNAP iSCSI Dead (x06); VNXe2 lỗi ngày 11/11 (x01) | Cao | Cao | Cao | Thay đĩa; dọn / mở rộng datastore; chốt RCA VNXe2 | | Mở |
| R-004 | VMware phiên bản cũ (ESXi 5.5 / 6.x, vCenter 6.7) | PCCE1 + .186 ESXi 5.5 ([[FSG01]]); VDC 6.0 / 6.7; Duy Tân / SMB 6.5 (x11) | Cao | Cao | Cao | Kế hoạch upgrade / thay host theo compatibility Cisco / Avaya | | Mở |
| R-005 | Single Point of Failure | PCCE1 / PCCE3 / CCX chạy local disk (không có FC); 1 FG / 1 RNET tại SMB; Heineken 1 node mỗi vai trò (x09); 1 FTTH VNPT ở VDC | TB | Cao | Cao | Đánh giá HA từng dịch vụ | | Mở |
| R-006 | Thiếu tài nguyên dự phòng (N+1) | VDC AppSvr failover capacity CPU 37% / RAM 27% (x06); PVB chỉ 3 host | TB | TB | TB | Tính N+1 theo cluster | | Mở |
| R-007 | Secret plaintext trong vault / sổ bàn giao | x12 RemoteGW (DB / Guacamole / LDAP), StorageLogin, license VMware, Matrix, BASE-Passwords header, một ô x09 trùng credential, 6 SSO vCenter + connect247.vn bị dán vào chat | Đã xảy ra | Cao | **Rất cao** | ✅ Chuyển file ra ngoài vault + `.gitignore`: [[2026-11-24-quarantine-credential-files]] (đã verify). ✅ Rotate credential: **chủ vault xác nhận đã xong 2026-11-24** (Claude chưa verify). Còn lại: import vào password manager, xóa thư mục quarantine | | Đã xử lý (chờ dọn quarantine) |
| R-008 | Backup chỉ cùng site, retention 2–7 ngày, chưa test restore | Mọi site (x08); chỉ GitLab có bản sang PVB | Cao | Cao | Cao | Thêm bản off-site / immutable; diễn tập restore | | Mở |
| R-009 | Bề mặt public / policy rộng | SSL-VPN 221.132.28.186:10443 + IPsec .188 (VDC); 39 policy ALL trên FG VDC; trunk 1–4094; FPT Cloud POC: RDP 13389, APISIX mở cho mọi nguồn, MGMT-to-Internet all (x06, CONF) | TB | Cao | Cao | Rà policy last-hit; MFA cho VPN; tắt NAT của POC | | Mở |
| R-010 | Sự cố [[2026-11-11-FPTDC-host186-LUN-loss]] chưa có RCA | FPTDC VNXe2 / FC fabric / host .186 | TB | Cao | Cao | Thực hiện action A01–A08 | | Mở |
| R-011 | Thiết bị EOL / hết bảo hành, linh kiện hiếm (EMC 520-byte, BBU; C3650 / 3850 uptime ~9 năm) | Toàn bộ DC (x23, x06) | Cao | Cao | Cao | Quyết định gói bảo trì FPT / TPM; lộ trình refresh | | Mở |
| R-012 | Inventory sai lệch (x05, BG_Maintain có lỗi copy-paste) gây thao tác nhầm | CMDB | Cao | TB | TB | Lấy inventory live làm nguồn sự thật | | Mở |
| R-013 | Đường MPLS Eximbank chập chờn (track 196 đổi trạng thái 1215 lần; thiếu route .38) | [[Eximbank]] / RNET-02 VDC | TB | TB | TB | Thu log IP SLA, làm việc với carrier | | Mở |
| R-014 | ESXi VDC không đồng bộ NTP: 5/8 host, .125 lệch khoảng +8 giờ. Hệ quả: log và timeline RCA sai giờ, guest lệch giờ, lỗi Kerberos/SSO | VDC .24 / .122 / .123 / .124 / .125 ([[2026-11-24-vsphere-health-VDC]]) | Đã xảy ra | TB | **Cao** | CR bật NTP và thống nhất nguồn NTP (.120.20 hay .120.21) | | Mở |
| R-015 | AppSvr Cluster VDC: EVC off với 3 đời CPU, 4 build ESXi khác nhau, DRS off, host isolation và APD/PDL off. vMotion bị hạn chế, gây khó khi bảo trì hoặc reboot host (.123 đang chờ reboot) | VDC AppSvr ([[2026-11-24-vsphere-health-VDC]]) | Cao | TB | Cao | Lộ trình chuẩn hóa / nâng cấp; lập kế hoạch evacuate .123 | | Mở |
| R-017 | **FHN01 A-App Cluster (6 host, VietinBank PROD / UAT, CN247 standby, TPBank, Lotte): vSphere HA OFF, DRS OFF.** Host lỗi thì VM không tự khởi động lại | [[FHN01]] (live 2026-11-24) | TB | **Cao** | **Cao** | CR bật HA. Trước đó cần kiểm tra admission control vì RAM đã 70% | | Mở |
| R-018 | **Host .47 PCCE3-B lỗi quạt CRITICAL từ 19/12/2024**, alarm bị ack nên ẩn. PCCE3 chạy local disk, không có HA phần cứng | [[FHN01]] / [[VietinBank]] | Cao | Cao | **Cao** | Kiểm tra CIMC, mở case thay quạt (cần bảo trì) | | Mở |
| R-019 | FHN01 datastore Cust_SAN.BK 91%, Cust_SVR.01 86% (CRITICAL); Unity300 hỏng đĩa liên tục | [[FHN01]] | Cao | Cao | Cao | Dọn hoặc mở rộng dung lượng; không đặt thêm workload mới | | Mở |
| R-020 | FHN02 PVB: RAM 77%, không đạt N+1 (mất 1 host thì còn khoảng 747 GB so với 858 GB đang dùng); UnityHN02_LUN01 91%; DRS ở chế độ Manual | [[FHN02]] / [[HD-SAISON]] (live 2026-11-24) | TB | Cao | Cao | Nâng RAM hoặc thêm host trước khi đặt workload mới; chuyển VM sang LUN02 | | Mở |
| R-021 | **VTB CRM v4 PG02 (172.31.90.32) sắp đầy disk `/`**: Warning 80% khoảng 09–13/12/2026, Critical khoảng 01/2027, đầy khoảng 03/2027 (+1.2–1.7 GiB/ngày); data PG nằm chung `/` | [[_VTB-CRMv4-DB]] / [[VietinBank]] | Cao | **Cao** (PROD ngân hàng) | **Cao** | Mở rộng disk hoặc tách data disk qua CR, hoặc v5 go-live và migrate trước 01/2027 | | Mở |
| R-022 | Sizing uCRM v5 600 GB / node không đủ (cần khoảng 1.5 TB); LUN02 PVB không chứa nổi cụm v5 (khoảng 4.8 TB) cùng kế hoạch giảm tải LUN01 | [[2026-11-24-danh-gia-trien-khai-ucrm-v5-HA]] | Cao | Cao | Cao | Mở rộng storage Unity380 PVB / thin provision có giám sát | | Mở |
| R-023 | Cả 2 cụm FortiGate FHN1 / FHN2 tắt session pickup (`ses_pickup: disable`): failover FW ngắt mọi session TCP (App↔DB, replication, etcd, SIP/CTI) | [[FHN01]] / [[FHN02]] (CLI 24/11) | TB | TB–Cao | TB | CR bật `session-pickup` (cân nhắc tải); chạy trước khi đưa HA DB liên site vào | | Mở |
| R-024 | FortiGate FHN1 cluster uptime 2,969 ngày (từ 12/2018), FortiOS 5.6.6: nhiều năm không vá; lần reboot / nâng cấp đầu tiên rủi ro cao. Liên quan R-001 | [[FHN01]] (CLI 24/11) | Cao | Cao | **Cao** | Lộ trình nâng FortiOS theo từng bước có cửa sổ bảo trì; backup config; kiểm tra subscription | | Mở |
| R-016 | CUCM 12.0 Publisher nhóm B (B-CUCMPUB 10.169.183.22) chạy CPU ~100% kéo dài | VDC host .23 | Đang xảy ra | TB–Cao (call control) | Cao | Điều tra RTMT (`cc-echo`); cân nhắc tăng vCPU theo OVA | | Mở |
