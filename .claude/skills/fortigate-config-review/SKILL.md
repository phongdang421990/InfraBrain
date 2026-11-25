---
name: fortigate-config-review
description: Audit file backup config FortiGate (FortiOS .conf) — firewall policy, VIP/NAT, address object, VPN, admin access, HA, logging — tìm rủi ro bảo mật và rác cấu hình, xuất báo cáo và inbound mapping. Dùng khi review bảo mật firewall hoặc tiếp nhận firewall mới.
---

# FortiGate config review

## Đầu vào
Backup config (System → Configuration → Backup, hoặc `show full-configuration` lưu ra file), đặt ở `90-Raw/configs/`.
Trước khi phân tích: che `set password ENC ...`, `set psksecret ENC ...`, `set passwd`, SNMP community khi trích vào note.

## Checklist
**Policy (`config firewall policy`)**
- srcaddr/dstaddr = "all" kèm service = "ALL" → 🔴
- Policy có `set status disable` lâu ngày → dọn
- Policy bị shadow (policy phía trên đã bao trùm) → 🟡
- Thiếu `set logtraffic all` trên policy WAN→LAN → 🟡
- Policy không có comment/không rõ mục đích → hỏi chủ vault

**VIP / NAT**
- VIP publish port quản trị (22, 23, 3389, 443 admin, 8443, 1433, 5432) ra Internet → 🔴
- VIP không có policy nào dùng → mồ côi

**Admin & management**
- `config system interface`: `allowaccess` có https/ssh/telnet/http trên interface WAN → 🔴
- `config system admin`: thiếu `trusthost`, không 2FA → 🟡
- Telnet/HTTP bật ở bất kỳ đâu → 🟡

**VPN**
- IPsec phase1/phase2 dùng DES/3DES/MD5/SHA1, DH group < 14 → 🟡
- SSL VPN: thiếu MFA, portal cho phép split tunnel tới "all" → 🟡

**HA & hệ thống**
- `config system ha`: mode, priority, monitor interface, session-pickup, heartbeat dùng ≥ 2 link
- Firmware version so với khuyến nghị của Fortinet (tra cứu, ghi nguồn)
- NTP, syslog/FortiAnalyzer, SNMP được cấu hình

## Đầu ra
1. `80-Reports/security/fortigate-<hostname>-YYYY-MM-DD.md`: phát hiện theo mức độ, policy ID, đề xuất (kèm CLI dự kiến — chỉ để duyệt).
2. Bảng inbound mapping: `Public IP:port → VIP → Internal IP:port → Policy ID → Dịch vụ → Khách hàng` cập nhật vào note firewall trong `10-Systems/`.
