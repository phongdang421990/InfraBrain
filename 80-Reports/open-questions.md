---
type: open-questions
updated: 2026-11-27
tags: [handover]
---
# Câu hỏi mở / cần xác minh

Danh sách 92 câu hỏi rà soát bàn giao (Q001–Q092) nằm trong `90-Raw/BaseBS-Handover-2026-11/01-Tong-hop-cu/BASEBS_INFRA_HANDOVER_NOTES_13-11-2026.md`; không nhân bản ở đây.

Các câu dưới đây được nạp ngày 2026-11-24 từ [[BaseBS-Infra-Master-Overview]] §7–§8. Mã K là số mâu thuẫn trong §7 của báo cáo đó.

| # | Câu hỏi | Hệ thống | Nguồn mâu thuẫn | Hỏi ai | Trạng thái | Trả lời |
|---|---|---|---|---|---|---|
| 1 | SMB thực tế có 1 hay 2 FortiGate, 1–3 RNET? IP mgmt từng FG? 10.189.110.1 có phải SVI? (K15) | [[FSG02]] | DeviceList / BG vs rack | Network | Mở | |
| 2 | vCenter SMB = 10.189.110.10? Host .23 / .24 còn trong cluster không? (K14, K16) | [[FSG02]] | x11 vs x14 | VMware | **Đã trả lời** | Live 25/11: vCenter SMB = 10.189.110.10 (vcsa.smbbasebs.com 6.5). Cluster-01 chỉ có 3 host .21 / .22 / .25; host .23 / .24 không có trong vCenter (còn gắn vật lý hay không chưa rõ). [[2026-11-25-vsphere-health-FSG-FHN]] |
| 3 | CLD.FW / CLD.RNET ở FSG01 là gì? 2 FG trong DC4-C5 trùng serial / IP với FW02 PVB? SG03 đặt ở đâu? (K13, K33) | [[FSG01]], [[FHN02]] | rack, BG, x05 | Network / DC | Một phần | K33: FW02 (…5355) đang trong cụm HA ở PVB (CLI 24/11) → bản ghi DC4-C5 sai. **25/11: VM SG03 (10.148.x) chạy trên SG02 Cluster01 (vcsa.sg02basebs.com, FSG01)**. K13 (CLD.FW / CLD.RNET) vẫn mở |
| 4 | Có leased line DC↔DC nào không (MetroNet PVB ↔ Duy Tân)? BaseBS đã khai "chỉ có VPN S2S" (K20) | [[VietinBank]] | [VAULT] vs x21 / x06 | Đăng | **Đã trả lời** | 24/11 CLI: không có kênh DC↔DC của BaseBS. FHN1 .51 và FHN2 .50 cùng nằm trong segment Metro FPT của HDSS 192.168.100.48/29 (của khách hàng). Kênh mới đề xuất 10.179.254.0/30 ([[FHN02]]) |
| 5 | Default route "FPT Gateway" 10.169.10.100 ở VDC là thiết bị nào? | [[VDC-VNPT]] | x06 | Network | Mở | |
| 6 | BVB = Bảo Việt Bank hay BVBank? VIKKI = DongA? | khách hàng | x05 / x18 | Kinh doanh | Mở | |
| 7 | Router MPLS FSG01 (2911 10.127.109.2 vs .129.2) — nghiêng về .109.2; RNET FHN01 là 4331 hay 4431, RNET-02 .101 hay .102? (K10–K12) | FSG01 / FHN01 | x14 vs rack / BG | Network | Đang nghiêng | |
| 8 | Ai đã đổi uplink vSwitch trên host .186? (K27) | [[2026-11-11-FPTDC-host186-LUN-loss]] | x11 vs x01 | VMware | Mở | |
| 9 | Host .186 / .188 đặt ở rack nào? | FSG01 | — | DC | **Đã trả lời** | DC4-C6 [1N BG] |
| 10 | Rotate credential đã lộ; chuyển sổ mật khẩu ra khỏi vault | R-007 | — | Đăng | Mở | |
| 11 | Có export VM 1:1 (ExportList.csv) cho từng vCenter không? | tất cả | x06 EV10 | VMware | Một phần | 25/11 đã đọc live danh sách VM (số lượng, trạng thái, dung lượng) của 5 vCenter; chưa có file export. Dùng script PowerCLI của skill `vsphere-health-check` để xuất |
| 12 | Chấp nhận mã site FSG01 / FSG02 / FHN01 / FHN02 / VDC làm tên chuẩn? | vault | — | Đăng | Mở | |
| 13 | Share backup VDC là 10.169.120.6 hay .9? (K31) | VDC | x08 | DevOps | Mở | |
| 14 | RNET-02 VDC: mgmt 10.169.110.8 và DeviceList 10.169.10.101 có phải cùng một thiết bị? (K10) | VDC | x06 vs x14 | Network | Mở | |
| 15 | Unity300 Duy Tân thực tế có expansion 6 TB không? (K24) | FHN01 | x14 DeviceList vs StorageInfo | Storage | Mở | |
| 16 | Một ô ở x09 R11 (Heineken) trùng giá trị với một credential: kiểm tra file gốc, nếu là password yếu thì rotate | [[Heineken]] | x09 MASKED-LEAK | Đăng | Mở | |
| 17 | vietjet.connect247.vn có còn chạy không (DNS ghi "Remove", proxy VDC vẫn còn)? | [[VietJet]] | NOTES vs x06 | App | Mở | |
| 18 | Thiết bị "VNPT-CORE-SW" và "LIGHTSMART" trong DC4-C6 là của ai? | FSG01 | rack | DC | Mở | |
| 19 | DB VTB CRM v4: IP 172.31.90.51–53 (x18) hay 172.31.90.32 (Checkmk PG02)? Hai cụm khác nhau hay đổi IP? Tên/IP 3 node Patroni, node nào primary? | [[_VTB-CRMv4-DB]] | x18 vs Checkmk 23/11 | Ngân / DBA | Một phần | Live 24–25/11: cụm v4 = VTB_uCRMv4_DB01–03 172.31.90.31–.33 (bật). Dải .51–.55 là cụm uCRM cũ: DB02 .52 tắt, DB05 .55 bật. Primary chưa xác minh (`patronictl list`) |
| 20 | VTB uCRM v5 đã go-live chưa? RPO/RTO VietinBank yêu cầu? (quyết định dựng HA trước go-live hay "Std trước, HA sau") | [[VietinBank]], [[2026-11-24-ket-noi-FHN01-FHN02-app-db]] | — | Anh Thanh / dev | Mở | 25/11: đã có VTB_uCRMv5_App01 172.31.185.80 và VTB_uCRMv5_DB01 172.31.90.101 đang bật (bản Std). Trạng thái go-live và RPO/RTO vẫn chưa rõ |
| 21 | FHN1.ExtSW Gi1/0/6 routed 10.179.255.5/30 (shutdown, không description) từng dùng cho việc gì? Có xóa cấu hình không? | [[FHN01]] | CLI 24/11 | Network | Mở | |
| 22 | Route backup TPBank qua VNPT trên FHN1.ExtSW trỏ 172.16.252.82 nhưng không có interface trong dải này: backup VNPT còn hoạt động không? | [[FHN01]] | CLI 24/11 | Network | Mở | |
| 23 | FHN2: Gi2/0/15 VNPT-WAN, Gi1/0/16 FPT-WAN, Gi1/0/17 / Gi2/0/17 SIP đang notconnect. Đường nào đã bỏ, đường nào đang mất? | [[FHN02]] | CLI 24/11 vs x05 | Network | Mở | |
| 24 | FHN1.ExtSW Gi1/0/15 up ở VLAN 1, không cấu hình: thiết bị gì đang cắm? (`show cdp neighbors Gi1/0/15 detail`) | [[FHN01]] | CLI 24/11 vs x05 | Network | Mở | |
| 25 | Vì sao SG02 .22 khởi động lại đêm 12/11 (khoảng 03:00) và vì sao vCenter SG02 (chạy trên .22) chỉ được bật lại khoảng 09:51? Có thao tác trong rack DC4 khoảng 01:53–03:05 không? | [[2026-11-11-FPTDC-host186-LUN-loss]], [[FSG01]] | Live 25/11 | VMware / DC FPT | Mở | |
| 26 | vCenter FPTDC 10.0.3.50 có license hợp lệ không? (alarm "Expired vCenter Server license" từ 16/12/2018, đã ack; H5 client 6.5 không xem được Licensing) | [[FSG01]] | Live 25/11 | VMware | Mở | |
| 27 | Datastore Unity_DAE01_Backup02 mount ở cả vCenter FPTDC và SG02: vCenter nào sở hữu? Template oracle8.10 đăng ký ở 2 nơi, giữ bản nào? | [[FSG01]] | Live 25/11 | VMware / Storage | Mở | |
| 28 | Cụm PROD_IC ở FHN02 (App01 / 02, DB01–04, Elk, khoảng 2.5 TB) đang tắt: đã ngừng dùng chưa, xóa để giải phóng LUN01 (91%) được không? | [[FHN02]] | Live 25/11 | App / Đăng | Mở | |
| 29 | SMB: Wazuh, SELKs, LogSvr, Expressway C / E SUB, PROD_ReverseProxy01, PROD_UnifyCRM_App03 đang tắt: có chủ ý không? | [[FSG02]] | Live 25/11 | System / App | Mở | |
| 30 | FPTDC có 53 VM tắt (15.7 TB; lớn nhất 02_b2oraiq1 4.2 TB, 02_b3oraiq2 3.25 TB, 02_b1b2_iqdb 2.18 TB): giữ, lưu trữ hay xóa? | [[FSG01]] | Live 25/11 | Đăng / khách hàng | Mở | |
| 31 | VNXe3200 #1 (10.0.4.11) không có datastore nào trong vCenter FPTDC: còn dùng cho việc gì? | [[FSG01]] | Live 25/11 vs x14 | Storage | Mở | |
| 32 | Datastore SG02 tên "Unity_DAE01_Backup02 / 03" đang chứa VM PROD: thuộc pool / loại đĩa nào của Unity380XT (NL-SAS?)? | [[FSG01]] | Live 25/11 | Storage | Mở | |
| 33 | LAB vCenter 172.23.90.10 chưa rà được (cần đăng nhập SSO `vcsa.labbasebs.com`) | [[FSG02]] | — | Đăng | Mở | |
| 34 | VTB_MID_App01 / 02 (172.31.182.51 / .52) đang tắt, 400 GiB trên Cust_SVR.01: đã ngừng dùng chưa, xóa được không? | [[FHN01]] | Live 25/11 | App (anh QuangBA) | Mở | |
| 35 | Disk rời `VTB_Calabrio_DB02_172.31.253.92_2.vmdk` (200 GiB, 08/2023) không gắn VM nào: còn cần không? | [[FHN01]] | Live 25/11 | Team Calabrio | Mở | |
| 36 | `[Cust_SAN.BK] A-CCX02/Local01, Local02` (1.146 GiB, chép 02/12/2025): giữ để làm gì, chuyển sang NAS hay xóa? | [[FHN01]] | Live 25/11 | Anh Tín / Đăng | Mở | |
| 37 | VTB_uCRMv4_MidDB (.90.34) và VTB_uCRM_DB02 (.90.52) đang tắt: xóa được không? | [[FHN01]] | Live 25/11 | App | Mở | |
| 38 | Thời hạn lưu ghi âm VTB theo hợp đồng? DFS02 có phải bản sao của DFS01 (DFS-R)? | [[VietinBank]] | Live 25/11 | VTB / team Calabrio | Mở | |
| 39 | CN247 standby ở FHN01 (23 VM, 1,9 TB, 186 GB RAM) còn cần không? | [[FHN01]] | Email anh Thanh 25/11 | Anh Thanh / Đăng | Mở | |
| 40 | HNK AICC: có cần làm media_timeout trong vars.xml và dòng xoá sip_profiles/*.xml (HD 1.0.10 §4.2–4.3) không? | [[Heineken]] | Kiệt chỉ chốt migration + CDR 1.0.9; HD 1.0.10 ghi bắt buộc | Anh Kiệt | Mở (đã hỏi trong email 27/11) | |
| 41 | Máy DB HNK có backup tự động hằng đêm thật không (`/db-backup/file-backup/`)? Là đường lùi duy nhất sau nâng cấp 1.0.11 | [[Heineken]] | Tài liệu cài DB nói có, chưa kiểm live | Đăng | Mở | |
| 42 | File `aicc.service` 1.0.9 trên Drive bị cụt dòng ExecStartPre: đã nhờ sửa chưa? | [[Heineken]] | systemd-analyze: Unbalanced quoting | Anh Kiệt / anh Minh | Mở (đã báo trong email 27/11) | |
| 43 | 10.189.120.20 (NTP đang cấu hình trên SMB .21 / .22) là máy gì, còn chạy không? Nguồn NTP chuẩn cho SMB là .120.20 hay AD .120.21, và AD SMB lấy giờ từ đâu? | [[FSG02]] | Live 25/11: .120.20 không có trong inventory; VDC / FHN02 dùng AD .120.20 + VM NTP .120.21 | Đăng (pre-check 0b của [[2026-11-27-ntp-esxi-smb]]) | Mở | |
| 44 | VM nào chạy trên PCCE3 .45 / .47 (vai trò, side)? Domain PCCE3 lấy giờ từ đâu (PDC nào)? Có VM nào bật "Synchronize guest time with host" không? | [[VietinBank]] / [[FHN01]] | Vault chưa có | Đăng / team PCCE (pre-check 0c và cc-echo mục B của [[2026-11-27-ntp-esxi-pcce3-fhn01]]) | Mở | |
| 45 | Phần mềm và lịch backup (snapshot) cho VM ở SMB Cluster-01 và PCCE3? Cần để chọn cửa sổ 2 CR NTP | [[FSG02]] / [[FHN01]] | Vault chưa có | Đăng / anh Tín | Mở | |
| 46 | Quy trình báo change cho VietinBank (đầu mối, thời hạn báo trước, có cho gọi test không) và lịch go-live uCRM v5? | [[VietinBank]] | Mục SLA / liên hệ còn trống; email phongth 23/11 chỉ nói "sắp go-live" | Anh Phong / anh Thanh | Mở | |

Các mâu thuẫn K1–K9, K17–K19, K21–K26, K28–K30, K32 đã có hướng chốt (xem §7 báo cáo). Chúng chỉ cần xác nhận live, không cần hỏi thêm.
