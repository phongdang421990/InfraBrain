---
type: report
status: final
updated: 2026-11-24
tags: [report, health-check, vsphere, vdc, basebs]
---
# Health check vSphere: VDC (vcsa.basebs.com): 2026-11-24

- **Nguồn:** vSphere Client UI **live**, đọc trong khoảng 16:05–16:30 ngày 2026-11-24 (UTC+7) qua Claude in Chrome. Đăng tự đăng nhập.
- **Chỉ đọc:** chỉ bấm vào cây inventory, các tab, menu điều hướng, bộ lọc hiển thị và nút mở rộng mục. JavaScript chỉ dùng để cuộn và đọc text của trang. **Không** bấm Acknowledge, Reset, Renew, Rescan, Edit, Power hay console.
- Liên quan: [[VDC-VNPT]] · [[BaseBS-Infra-Master-Overview]] · [[risk-register]] · [[VietJet]] · [[Eximbank]]

## 1. Tóm tắt
| Mức | Phát hiện |
|---|---|
| 🔴 | **NTP: chỉ 3/8 host đồng bộ thời gian.** .24, .122, .123: NTP service *Stopped*. .124, .125: NTP client *Disabled*, không có server. **Host .125 lệch khoảng +7 giờ 57 phút**; .24 lệch −22 phút, .122 −18 phút, .123 −7.6 phút, .124 −6 phút. Hệ quả: log và timeline RCA sai giờ; guest có thể lệch giờ nếu đồng bộ qua VMware Tools; nguy cơ lỗi Kerberos/SSO |
| 🔴 | **AppSvr Cluster trộn 4 build ESXi:** 6.0.0 b5050593 / b10719132 / b13635687 và 6.7.0 b20497097. Đồng thời trộn 3 đời CPU (E5-2650 v4, Gold 5220, Gold 6442Y) trong khi **EVC Disabled**. vMotion giữa các đời CPU sẽ bị chặn; HA restart vẫn chạy được. Host R660xs (.125) chạy ESXi 6.7 nhiều khả năng **ngoài HCL** |
| 🔴 | **DRS OFF.** HA ON nhưng *Host Isolation = Disabled* (VM tiếp tục chạy khi host bị cô lập) và *PDL/APD protection = Disabled* |
| 🔴 | **4 host CCX (.21–.24) chạy standalone, không có vSphere HA.** ESXi 6.0.0 b3073146 (2015) và 6.5.0 b8294253 (2018). Uptime .21 / .22 khoảng 8.2 / 9.2 năm |
| 🟠 | **VM B-CUCMPUB (10.169.183.22, CUCM 12.0 Publisher nhóm B, chạy trên host .23) đang ở mức CPU ~100%** (6.35 GHz trên 2 vCPU). Trong 1 giờ qua liên tục chạm 100% từng đợt, trung bình khoảng 70%. Có alarm "Virtual machine CPU usage". VM hardware version 8 |
| 🟠 | **Unity380_Datastore1 dùng 84%**, alarm đã bị ack nên không hiện trong All Issues. Lúc 14:21 host .123 báo I/O latency cao trên LUN Unity `naa.60060160b6b8…`, hồi phục sau khoảng 1 phút |
| 🟡 | Host .123 báo *Reboot Required*. Chứng chỉ của .123 **được renew ngày 20/11/2026** (hiệu lực đến 2030), có thể là nguyên nhân. Note cũ ghi "cert hết hạn 31/10" **đã lỗi thời** |
| 🟡 | Alarm datastore A-CCX-02 (79%) và B-CCX-02 (81%) treo từ 12/2023 và 01/2024 |
| 🟡 | Port group đặt tên không thống nhất: có cả `A-CCX-vlan182` và `A.CCX-VLAN182`, `B-CCX-VLAN183` và `B.CCX-VLAN183`. Toàn bộ dùng Standard vSwitch, **không có vDS** |
| 🟡 | Có 4 VM Powered Off: B-UCCX01, BASE_uCRMv3_Elastic, cùng 2 template. Chiếm khoảng 400 GB |
| 🟢 | Chứng chỉ cả 8 host: Good, hiệu lực đến 2029–2030. License: vSphere 6 Enterprise Plus, perpetual |
| 🟢 | 8/8 host Connected / Normal, không có hardware sensor nào báo lỗi. Admission control giữ lại 37% CPU / 27% RAM, đủ chịu 1 host lỗi |

## 2. vCenter
- vcsa.basebs.com (10.169.110.12), **6.7.0 build 24323669**. vCenter HA chưa cấu hình. 1 datacenter "VDC HCM".
- **8 host, 107 VM** (103 đang chạy, 4 tắt). Tab Datacenter đếm 113 do có tính cả template và các đối tượng khác.
- Tổng tài nguyên: CPU 47 / 468 GHz (10%), RAM 865 GB / 1.68 TB (51%), storage 32.14 / 49.25 TB (65%).
- Có tích hợp Update Manager, nhưng host baseline ghi "never checked".
- Storage Unity (10.169.110.9) đăng nhập vào host bằng `root` qua gSOAP theo định kỳ (Unity VMware integration).

## 3. Hosts
| Host | Nhóm | Model | CPU | RAM dùng / tổng | ESXi | VM | Uptime | NTP | Lệch giờ | Cert hết hạn |
|---|---|---|---|---|---|---|---|---|---|---|
| .21 | A-CCX (folder) | UCS C240 M4S2 | 2× E5-2680 v3 (24 LP) | 42 / 64 GB | 6.0.0 b3073146 | 5 | 3000 ngày | Running | (chưa đo) | 23/02/2030 |
| .22 | A-CCX (folder) | UCS C240 M4S2 | 2× E5-2680 v3 (24 LP) | 30 / 64 GB | 6.0.0 b3073146 | 3 | 3350 ngày | Running | (chưa đo) | 23/02/2030 |
| .23 | B-CCX (folder) | BE7M-M5-K9 | 1× Gold 6132 (28 LP) | 19 / 95 GB | 6.5.0 b8294253 | 3 | 2706 ngày | Running | −6 s | 23/02/2030 |
| .24 | B-CCX (folder) | BE7M-M5-K9 | 1× Gold 6132 (28 LP) | 27 / 95 GB | 6.5.0 b8294253 | 2 | 1275 ngày | **Stopped** | **−22 phút** | 23/02/2030 |
| .122 | AppSvr | UCS C240 M4S | 2× E5-2650 v4 (48 LP) | 89 / 256 GB | 6.0.0 b5050593 | 9 | 413 ngày | **Stopped** | **−18 phút** | 23/02/2030 |
| .123 | AppSvr | PowerEdge R640 | 2× Gold 5220 (72 LP) | 262 / 383 GB | 6.0.0 b10719132 | 34 | 1536 ngày, *Reboot Required* | **Stopped** | **−7.6 phút** | 17/03/2030 (renew 20/11/2026) |
| .124 | AppSvr | PowerEdge R640 | 2× Gold 5220 (72 LP) | 283 / 383 GB (74%) | 6.0.0 b13635687 | 34 | 833 ngày | **Disabled** | **−6 phút** | 12/08/2029 |
| .125 | AppSvr | PowerEdge R660xs | 2× Gold 6442Y (96 LP) | 112 / 383 GB | **6.7.0** b20497097 | 17 | 413 ngày | **Disabled** | **+7 giờ 57 phút** | 17/03/2030 |

NTP server cấu hình trên các host là `10.169.120.20` (VM BASE_Infra_PDC). Trong khi đó tồn tại riêng một VM `BASE_Infra_NTP_10.169.120.21` mà không host nào trỏ tới.
Lệch giờ được đo bằng cách so trường "Date & Time" trên UI với đồng hồ trình duyệt; sai số khoảng ±10 s. Host .23 dùng làm mốc (lệch −6 s).

## 4. AppSvr Cluster
- 4 host, 94 VM, 144 logical CPU. Tổng 68 lần vMotion.
- **DRS: OFF.** Proactive HA: không khả dụng (cần DRS). **EVC: Disabled.**
- **vSphere HA: ON.**
  - Host failure → Restart VMs.
  - Host isolation → **Disabled** (VM vẫn chạy khi host bị cô lập).
  - PDL/APD → **Disabled**.
  - Admission control: giữ lại 37% CPU / 27% RAM.

## 5. Datastores (15, đều VMFS5 trừ SVR-05 là VMFS6)
| Datastore | Dung lượng | Trống | Dùng | Ghi chú |
|---|---|---|---|---|
| Unity380_Datastore1 | 17.68 TB | 2.8 TB | **84%** | Warning, alarm đã ack bởi `BASEBS\vinhlq` |
| Unity380_Datastore2 | 11 TB | 4.57 TB | 58% | |
| Cust_LUN-01 | 7 TB | 1.91 TB | 73% | |
| Infra_LUN-01 | 1,023.75 GB | 339 GB | 67% | |
| A-CCX-01 / A-CCX-02 | 1.35 / 1.36 TB | 372 / 293 GB | 73% / **79%** | CCX-02: Warning từ 09/01/2024 |
| B-CCX-01 / B-CCX-02 | 1.35 / 1.36 TB | 627 / 259 GB | 55% / **81%** | CCX-02: Warning từ 07/12/2023 |
| B-CCX01-Local01 / Local02 / B-CCX02-Local01 | ≈1.62 TB mỗi cái | 1.15 / 1.35 / 1.25 TB | 23–29% | |
| SRV-02 / SRV-03 / SRV-04 / SVR-05 | 550 / 886 / 439 / 439 GB | gần như trống | ≈1% | Khoảng 2.3 TB đang bỏ phí |

## 6. VM (107)
- Trạng thái: 102 Powered On/Normal, **1 Powered On/Alert** (B-CUCMPUB), **4 Powered Off** (B-UCCX01-10.169.183.20, BASE_uCRMv3_Elastic_10.169.182.75, Debian12.8-template, Oraclelinux-8.10v1).
- Dung lượng (100/107 VM đọc được từ lưới, đã đủ 9 VM VJA nhờ lọc): provisioned khoảng 23.3 TB, used khoảng 21.9 TB, tức gần như toàn bộ là thick hoặc đã đầy.
- VM lớn nhất:

| VM | Provisioned / Used |
|---|---|
| VJA_CALABRIO10_WEBCORE_10.169.182.66 | **5.82 TB / 5.82 TB** |
| CUSTS_CALABRIO10_PLATCORE_10.169.182.60 | 3.24 / 3.23 TB |
| DAIKIN_PFCORE_10.169.182.80 | 1.69 / 1.69 TB |
| BASE_Infra_SELKs_10.169.110.30 | 1 / 1 TB |
| BASE_Infra_Wazuh_10.169.120.22 | 1016 / 643 GB |
| VJA_sFTP_Backup_10.169.182.72 | 744 GB |
| BASE-UCCX01 / BASE-UCCX02 | 698 / 714 GB |

- VietJet (9 VM `VJA_*`): đều Powered On/Normal.
- **Chưa kiểm tra:** snapshot và VMware Tools theo từng VM (lưới không có cột này, phải mở từng VM).

## 7. Network (18 Standard port group, không có vDS)
| Port group | VM | Host |
|---|---|---|
| A-CCX-vlan182 | 39 | 4 |
| A.CCX-VLAN182 | 8 | 2 |
| B-CCX-VLAN183 | 16 | 5 |
| B.CCX-VLAN183 | 2 | 1 |
| Cn247-vlan184 | 15 | 4 |
| DB-vlan188 | 14 | 4 |
| SYS-vlan120 | 9 | 4 |
| PUBLIC-vlan90 | 4 | 4 |
| MGT-vlan110 | 2 | 4 |
| Lcm-vlan185 | 2 | 4 |
| Interact-190, WFM-189, Local, Mirror | 1 mỗi cái | |
| DMZ-vlan70, IBOX-181, SonyApp-Vlan186, Ucrm-vlan187 | 0 | |

`Mirror` có thể là port group dùng cho port mirroring (ghi âm, Calabrio). Cần xác nhận. Port group VLAN 186 và 187 không có VM nào.

## 8. Events (khoảng 3 giờ gần nhất, 13:17–16:17)
- 14:21: **I/O latency cao** trên LUN Unity `naa.60060160b6b85500b387836171d27bbc` (host .123), hồi phục lúc 14:22.
- 15:30 / 15:57: Hardware sensor của .24 và .125 đều green.
- Alarm CPU trên B-CUCMPUB đổi trạng thái liên tục.
- SSO: 1 lần đăng nhập thất bại từ 10.69.68.8 lúc 16:05:10, dùng tài khoản thuộc domain `ccxbasebs.com` (sai domain cho vCenter này), sau đó đăng nhập thành công bằng `basebs.com`. Khả năng cao là chính Đăng.

## 9. Đối chiếu với tài liệu
| Hạng mục | Tài liệu | Live | Kết luận |
|---|---|---|---|
| Host / VM | 8 / 107 | 8 / 107 | ✅ |
| vCenter | 6.7 | 6.7.0 b24323669 | ✅ |
| Datastore1 / Datastore2 | 84% / 58% | 84% / 58% | ✅ |
| AppSvr: model, HA on, DRS off, 94 VM | x06 | Khớp | ✅ |
| ESXi CCX 6.0 / 6.5 | x06 | 6.0.0 b3073146 / 6.5.0 b8294253 | ✅ + bổ sung build |
| Cert .123 hết hạn 31/10/2026 | [[VDC-VNPT]] | **Đã renew 20/11/2026**, hiệu lực đến 2030 | ✏️ Cập nhật |
| NTP | x06: "%NTP is not enabled" (switch) | 5/8 host không đồng bộ; .125 lệch +8 giờ | ➕ Mới |
| EVC / build trong cluster | (không có) | EVC off, 4 build khác nhau | ➕ Mới |

## 10. Đề xuất (việc nào thay đổi cấu hình đều qua `change-request`)
1. **NTP (ưu tiên 1, rủi ro thấp):** bật NTP client, start service, đặt policy "Start and stop with host" trên .24, .122, .123, .124, .125. Thống nhất nguồn NTP: .120.20 (PDC) hay .120.21 (VM NTP). Với .125 lệch 8 giờ: kiểm tra guest nào đang đồng bộ giờ qua VMware Tools trước khi chỉnh, tránh để giờ nhảy ngược.
2. **B-CUCMPUB CPU 100%:** điều tra ở tầng ứng dụng (CUCM RTMT, process). Dùng `cc-echo` / skill `pcce-troubleshooting`. Cân nhắc thêm vCPU theo đúng OVA template của CUCM 12 (là change).
3. **Datastore1 84%:** bỏ trạng thái ack cũ để alarm hiện lại; lập kế hoạch Storage vMotion sang Datastore2 hoặc tận dụng các LUN SRV-02/03/04/SVR-05 đang trống (khoảng 2.3 TB, nhưng là LUN nhỏ). Theo dõi latency của LUN Unity.
4. **Host .123 Reboot Required:** đưa vào maintenance mode và reboot qua CR. Trước đó cần lưu ý: EVC đang tắt nên **vMotion từ .123 (Gold 5220) chỉ đi được sang .124** (cùng đời CPU), mà .124 đã dùng 74% RAM. Cần lên kế hoạch chuyển VM cẩn thận.
5. **Chuẩn hóa cluster:** lộ trình nâng cấp ESXi và vCenter (6.x đã EOL), bật EVC ở baseline thấp nhất (Broadwell), cân nhắc bật DRS ở chế độ partially automated, bật host isolation response và APD/PDL.
6. Dọn dẹp: 4 VM tắt (khoảng 400 GB), 2 alarm CCX-02, port group trùng tên, VLAN 186/187 không dùng.
7. **Read-only tiếp theo:** kiểm tra snapshot và VMware Tools theo từng VM (mở từng VM, hoặc dùng PowerCLI `Get-Snapshot` khi Đăng đồng ý chạy).
