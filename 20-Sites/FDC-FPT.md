---
type: site
status: unverified
updated: 2026-11-24
tags: [site, moc, fpt]
---
# FDC / FPT (MOC)

[VAULT] Data Center thuộc phạm vi tiếp nhận hạ tầng của BaseBS. Có hệ thống PCCE1 và Avaya (đã từng điều tra sự cố tại đây).

Từ 2026-11-24, note này là **MOC** cho 4 DC của FPT. Chi tiết nằm ở từng note site. Nguồn tổng: [[BaseBS-Infra-Master-Overview]].

| Mã | Địa điểm / rack | Vai trò chính | Note |
|---|---|---|---|
| FSG01 | FPT Tân Thuận DC4 (C5, C6), HCM | FPTDC legacy: HDSS / PCCE1 / Avaya / CTI (vCenter 10.0.3.50); SG02 Cluster01 (vCenter 10.138.110.10); PA-3020 | [[FSG01]] |
| FSG02 | FPT Tân Thuận DC7-C12, HCM | SMB Connect247 Production + LAB / UAT; SG03 (?) publish qua edge SMB | [[FSG02]] |
| FHN01 | FPT Duy Tân CG3-i5, Hà Nội | PCCE3 / [[VietinBank]], CN247 standby, TPBank, Lotte | [[FHN01]] |
| FHN02 | FPT Phạm Văn Bạch L06-M3, Hà Nội | [[HD-SAISON]], UCRM Cloud / BaseApp | [[FHN02]] |

Nguồn bảng mã site: [2N] x11 StorageLogin (mã site ↔ dải IP) + x05 + báo giá FPT 07/10/2026.

## Điểm chung của các DC FPT
- Đều nằm trong phạm vi đề xuất Managed Service của FPT IS: 49 thiết bị mạng và 92 thiết bị phần cứng (báo giá 07/10/2026, đang đàm phán) [1N BG].
- Kết nối DC↔DC: **chỉ có IPsec site-to-site** qua Internet, hub tại RNET-01 [[VDC-VNPT]] [2N x06 + x21].
- Firewall: FortiGate 201E (FortiOS 5.6.6) và PA-3020 (PAN-OS 7.0), **đã hết subscription** [2N x21 + x23].
- Thiết bị đã hết bảo hành hãng; BaseBS có kho đĩa dự phòng [1N x23].

## Sự cố liên quan
- [[2026-11-11-FPTDC-host186-LUN-loss]] (FSG01)

## Cần xác minh
- Địa chỉ chính xác của từng DC; nguồn điện A/B (chưa có tài liệu).
- Xem mục "Cần xác minh" trong từng note site và [[open-questions]].
