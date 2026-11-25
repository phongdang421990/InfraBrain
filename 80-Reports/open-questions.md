---
type: open-questions
updated: 2026-11-24
tags: [handover]
---
# Câu hỏi mở / cần xác minh

Danh sách 92 câu hỏi rà soát bàn giao (Q001–Q092) nằm trong `90-Raw/BaseBS-Handover-2026-11/01-Tong-hop-cu/BASEBS_INFRA_HANDOVER_NOTES_13-11-2026.md`; không nhân bản ở đây.

Các câu dưới đây được nạp ngày 2026-11-24 từ [[BaseBS-Infra-Master-Overview]] §7–§8. Mã K là số mâu thuẫn trong §7 của báo cáo đó.

| # | Câu hỏi | Hệ thống | Nguồn mâu thuẫn | Hỏi ai | Trạng thái | Trả lời |
|---|---|---|---|---|---|---|
| 1 | SMB thực tế có 1 hay 2 FortiGate, 1–3 RNET? IP mgmt từng FG? 10.189.110.1 có phải SVI? (K15) | [[FSG02]] | DeviceList / BG vs rack | Network | Mở | |
| 2 | vCenter SMB = 10.189.110.10? Host .23 / .24 còn trong cluster không? (K14, K16) | [[FSG02]] | x11 vs x14 | VMware | Mở | |
| 3 | CLD.FW / CLD.RNET ở FSG01 là gì? 2 FG trong DC4-C5 trùng serial / IP với FW02 PVB? SG03 đặt ở đâu? (K13, K33) | [[FSG01]], [[FHN02]] | rack, BG, x05 | Network / DC | Một phần | K33: FW02 (…5355) đang trong cụm HA ở PVB (CLI 24/11) → bản ghi DC4-C5 sai. K13 và SG03 vẫn mở |
| 4 | Có leased line DC↔DC nào không (MetroNet PVB ↔ Duy Tân)? BaseBS đã khai "chỉ có VPN S2S" (K20) | [[VietinBank]] | [VAULT] vs x21 / x06 | Chủ vault | **Đã trả lời** | 24/11 CLI: không có kênh DC↔DC của BaseBS. FHN1 .51 và FHN2 .50 cùng nằm trong segment Metro FPT của HDSS 192.168.100.48/29 (của khách hàng). Kênh mới đề xuất 10.179.254.0/30 ([[FHN02]]) |
| 5 | Default route "FPT Gateway" 10.169.10.100 ở VDC là thiết bị nào? | [[VDC-VNPT]] | x06 | Network | Mở | |
| 6 | BVB = Bảo Việt Bank hay BVBank? VIKKI = DongA? | khách hàng | x05 / x18 | Kinh doanh | Mở | |
| 7 | Router MPLS FSG01 (2911 10.127.109.2 vs .129.2) — nghiêng về .109.2; RNET FHN01 là 4331 hay 4431, RNET-02 .101 hay .102? (K10–K12) | FSG01 / FHN01 | x14 vs rack / BG | Network | Đang nghiêng | |
| 8 | Ai đã đổi uplink vSwitch trên host .186? (K27) | [[2026-11-11-FPTDC-host186-LUN-loss]] | x11 vs x01 | VMware | Mở | |
| 9 | Host .186 / .188 đặt ở rack nào? | FSG01 | — | DC | **Đã trả lời** | DC4-C6 [1N BG] |
| 10 | Rotate credential đã lộ; chuyển sổ mật khẩu ra khỏi vault | R-007 | — | Chủ vault | Mở | |
| 11 | Có export VM 1:1 (ExportList.csv) cho từng vCenter không? | tất cả | x06 EV10 | VMware | Mở | |
| 12 | Chấp nhận mã site FSG01 / FSG02 / FHN01 / FHN02 / VDC làm tên chuẩn? | vault | — | Chủ vault | Mở | |
| 13 | Share backup VDC là 10.169.120.6 hay .9? (K31) | VDC | x08 | DevOps | Mở | |
| 14 | RNET-02 VDC: mgmt 10.169.110.8 và DeviceList 10.169.10.101 có phải cùng một thiết bị? (K10) | VDC | x06 vs x14 | Network | Mở | |
| 15 | Unity300 Duy Tân thực tế có expansion 6 TB không? (K24) | FHN01 | x14 DeviceList vs StorageInfo | Storage | Mở | |
| 16 | Một ô ở x09 R11 (Heineken) trùng giá trị với một credential: kiểm tra file gốc, nếu là password yếu thì rotate | [[Heineken]] | x09 MASKED-LEAK | Chủ vault | Mở | |
| 17 | vietjet.connect247.vn có còn chạy không (DNS ghi "Remove", proxy VDC vẫn còn)? | [[VietJet]] | NOTES vs x06 | App | Mở | |
| 18 | Thiết bị "VNPT-CORE-SW" và "LIGHTSMART" trong DC4-C6 là của ai? | FSG01 | rack | DC | Mở | |
| 19 | DB VTB CRM v4: IP 172.31.90.51–53 (x18) hay 172.31.90.32 (Checkmk PG02)? Hai cụm khác nhau hay đổi IP? Tên/IP 3 node Patroni, node nào primary? | [[_VTB-CRMv4-DB]] | x18 vs Checkmk 23/11 | Ngân / DBA | Mở | |
| 20 | VTB uCRM v5 đã go-live chưa? RPO/RTO VietinBank yêu cầu? (quyết định dựng HA trước go-live hay "Std trước, HA sau") | [[VietinBank]], [[2026-11-24-ket-noi-FHN01-FHN02-app-db]] | — | Anh Thanh / dev | Mở | |
| 21 | FHN1.ExtSW Gi1/0/6 routed 10.179.255.5/30 (shutdown, không description) từng dùng cho việc gì? Có xóa cấu hình không? | [[FHN01]] | CLI 24/11 | Network | Mở | |
| 22 | Route backup TPBank qua VNPT trên FHN1.ExtSW trỏ 172.16.252.82 nhưng không có interface trong dải này: backup VNPT còn hoạt động không? | [[FHN01]] | CLI 24/11 | Network | Mở | |
| 23 | FHN2: Gi2/0/15 VNPT-WAN, Gi1/0/16 FPT-WAN, Gi1/0/17 / Gi2/0/17 SIP đang notconnect. Đường nào đã bỏ, đường nào đang mất? | [[FHN02]] | CLI 24/11 vs x05 | Network | Mở | |
| 24 | FHN1.ExtSW Gi1/0/15 up ở VLAN 1, không cấu hình: thiết bị gì đang cắm? (`show cdp neighbors Gi1/0/15 detail`) | [[FHN01]] | CLI 24/11 vs x05 | Network | Mở | |

Các mâu thuẫn K1–K9, K17–K19, K21–K26, K28–K30, K32 đã có hướng chốt (xem §7 báo cáo). Chúng chỉ cần xác nhận live, không cần hỏi thêm.
