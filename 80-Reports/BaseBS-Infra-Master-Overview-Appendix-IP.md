---
type: report
status: review
updated: 2026-11-26
tags: [report, basebs, ip-plan, cmdb, appendix]
---
# Phụ lục IP — BaseBS Infra Master Overview

Đây là phụ lục của [[BaseBS-Infra-Master-Overview]]. Nhãn và mã nguồn dùng giống file chính.

Quy ước cột **Loại**:

| Loại | Ý nghĩa |
|---|---|
| M | Quản trị thiết bị |
| B | BMC (iDRAC / CIMC) |
| A | Ứng dụng |
| G | Gateway |
| P | Public |

Cột **BMC** của ESXi được giải mã từ ô Excel dạng số (ví dụ `1.0189110151E10` → 10.189.110.151), vì vậy cần xác minh lại trước khi dùng.

Không có username hay mật khẩu nào trong phụ lục này.

## A. VDC — VNPT Tân Thuận (10.169.0.0/16)

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 221.132.28.185 | Gateway FTTH VNPT | P/G | [2N] |
| 221.132.28.186 | RNET-01 WAN; SSL-VPN :10443 → FG | P | [2N] |
| 221.132.28.187 | NAT → 10.169.11.103:443 (VIP VJA proxy) | P | [1N] x06 |
| 221.132.28.188 | NAT UDP 500/4500 → FG; :9443 → PRTG | P | [1N] x06 |
| 10.169.10.99 | RNET-01 Gi0/0/0 (inside) | M | [2N] |
| 10.169.10.100 | "FPT Gateway" — next-hop default route của FG, thiết bị chưa rõ | G | [1N] |
| 10.169.10.101 | "Router Internet 02" theo DeviceList (mâu thuẫn K10) | M? | [1N] |
| 10.169.10.110 | FG wan1 | M | [2N] |
| 10.169.11.101 / .102 / .103 | Loopback FG (VIP PRTG / – / VJA) | A | [1N] |
| 10.169.20.234 | ExternalSW stack | M | [2N] |
| 10.169.20.123 / 10.169.30.123 | FG VLAN20 / VLAN30 | G | [2N] |
| 10.169.30.234 | RNET-02 Gi0/0/1.30 | G | [1N] |
| 10.169.70.11 / .12 / .13 | VoiceGW 01 / 02 / 03 | M | [2N] |
| 10.169.90.56 / .58 / .60 | cn247-lb01 / VIP / VJA proxy | A | [2N] |
| 10.169.110.1 | FG SVI MGT | G | [2N] |
| 10.169.110.5 / .6 | SAN switch fabric B / A | M | [2N] |
| 10.169.110.8 | RNET-02 mgmt | M | [1N] |
| 10.169.110.9 / .10 | Unity350F / Unity380 | M | [2N] |
| 10.169.110.12 | vCenter vcsa.basebs.com | M | [2N] |
| 10.169.110.20 | InternalSW stack | M | [2N] |
| 10.169.110.21 – .24 | ESXi A.CCX.01 / 02, B.CCX.01 / 02 | M | [2N] |
| 10.169.110.122 – .125 | ESXi SRV.02 / 03 / 04 / 01 | M | [2N] |
| 10.169.110.154 / .158 / .159 / .165 | BMC của .122 / .123 / .124 / .125 | B | [1N] |
| 10.169.110.155 / .156 | BMC của .23 / .24 | B | [1N] |
| 10.169.120.20 | AD / DNS | A | [2N] |
| 10.169.120.51 / .52 / .6 | Syslog / PRTG / share backup | A | [1N] |
| 10.169.184.51 / .52 / .55 / .57 / .91 / .92 | CN247 App / DB / App02 / File / CTI ×2 | A | [2N] |
| 10.169.249.1 / .90 / .91 | SVI / FG01 / FG02 mgmt | M | [2N] |
| 10.169.255.x | Địa chỉ IPsec tunnel RNET-01 (.6 / .9 / .33 / .45 / .57 / .61 / .77 / .81) | — | [1N] |

## B. FSG01 — FPT DC4 (10.0.3–4.x, 10.138.x)

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 192.168.3.1 | Router Internet Cisco 877 | M | [2N] |
| 192.168.4.1 | ExtSW C9300 (DeviceList; x05 ghi 10.0.20.234) | M | [1N] |
| 10.127.129.2 | Router MPLS 2911 (rack ghi 10.127.109.2) | M | mâu thuẫn |
| 10.0.4.31 / .32 | Palo Alto PA-3020 (x05 ghi HA 10.0.20.230) | M | [2N] |
| 10.0.4.21 / .22 | BE SW / DMZ SW (stack) | M | [2N] |
| 10.0.4.10 / .11 / .12 | Unity380XT / VNXe3200 #1 / #2 | M | [2N] |
| 10.0.4.100 / .97 | SAN switch A / B | M | [2N] |
| 10.0.4.178 / .188 | BMC của .178 / .188 | B | [1N] |
| 10.0.3.16 | CIMC 10.138.139.3 | B | [2N] |
| 10.0.3.20 / .47 | AD / DNS FDCHCM-Prod (.47 kiêm NTP) | A | [1N] |
| 10.0.3.50 | vCenter FPTDC | M | [2N] |
| 10.0.3.178 / .186 / .188 | ESXi DMZ / BACKEND (.186 = esx21) | M | [2N] |
| 10.0.3.252 | SVI BE-MGT VLAN 8 | G | [1N] |
| 10.138.20.252 / 10.138.110.252 | SVI ExtSW / DMZ | G | [1N] |
| 10.138.110.10 | vCenter vcsa.sg02basebs.com | M | [2N] |
| 10.138.110.21 / .22 / .23 | ESXi SG02 Cluster01 | M | [2N] |
| 10.138.110.151 / .152 / .153 | BMC SG02 | B | [1N] |
| 10.138.120.20 / .21 | AD / DNS SG02 | A | [1N] |
| 10.138.90.25 | DB RemoteGW sg02 | A | [1N] |
| 10.138.139.2 / .3 | ESXi PCCE1 | M | [2N] |
| 10.138.139.51 / .52 | VoiceGW C3900 | M | [2N] |
| 10.138.173.75 / .80 / .141 / .142 / .180 / .182 | Avaya G450 | M | [2N] |
| 10.138.173.81 | b1-gw2 (rack) | M | [1N] |
| 10.138.180.199 | Share backup HCM | A | [1N] |
| 10.138.180.200 | FDC.NAS01 (có route từ FG VDC) | A | [1N] |

## C. FSG02 — SMB / LAB (10.189.x, 172.17.x, 172.23.x)

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 210.245.72.172 | FSG2.R1 (peer IPsec VDC và FPT Cloud) | P | [2N] |
| 103.39.93.192/28 | WAN1 (RNET-01) | P | [2N] |
| 42.119.139.16/29 | WAN2 (RNET-02; dùng chung SG03) | P | [2N] |
| 43.239.148.240/29 | WAN3 (RNET-03, LAB / UAT) | P | [2N] |
| 10.189.10.101 / .102 | RNET-01 / 02 | M | [1N] |
| 10.189.13.101 | Router-LAB Cisco 1811 | M | [1N] |
| 10.189.14.109 | FW-LAB FG-201E | M | [1N] |
| 10.189.70.11 / .12 / .13 | VoiceGW 01 / 02 / VGW LAB | M | [2N] |
| 10.189.110.1 | Nhãn FIREWALL-01 trên rack (nhiều khả năng là SVI) | G | [SL] |
| 10.189.110.5 / .6 | SAN switch | M | [2N] |
| 10.189.110.9 | Unity380 | M | [2N] |
| 10.189.110.10 | vCenter (VI SDK); DeviceList ghi "switch 02" | M | [1N] |
| 10.189.110.20 | CoreSW C9300 stack | M | [2N] |
| 10.189.110.21 / .22 / .25 (+ .23 / .24) | ESXi | M | [2N] / [1N] |
| 10.189.110.151 / .152 / .155 | BMC | B | [1N] |
| 10.189.249.90 | FG (DeviceList ghi cho cả 2 FG) | M | [1N] |
| 10.189.120.21 / .23 / .5 / .26 / .27 | AD / GitLab / NFS backup / Restore01 / 02 | A | [2N] |
| 10.189.80.6 | Share backup | A | [1N] |
| 10.189.90.22 | DB RemoteGW connect247.vn | A | [1N] |
| 10.189.184.50 / .55 / .25 / .60 / .71–.73 | Proxy portal / SSO / Expressway / SIP / K8s CP | A | [2N] |
| 172.17.203.1 / .203 / .254 | Router-LAB / SW-LAB / FW-LAB (GW UAT) | M/G | [2N] x05 + x18 |
| 172.17.203.20 / .22 | AD UAT / reverse proxy UAT | A | [2N] |
| 172.17.203.241 / .244 / .248 / .249 / .252 | ESXi BASELAB | M | [2N] |
| 172.17.203.242 / .243 / .247 / .250 / .253 | BMC BASELAB | B | [1N] |
| 172.23.90.10 / .12 / .25 / .254 | vCenter LAB / AD / proxy LAB / GW | M/A | [2N] |

## D. FHN01 — Duy Tân (10.179.x, 172.31.x)

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 103.35.64.45 | FHN1.R1 (peer IPsec VDC) | P | [1N] x06 |
| 103.35.64.46 / .47 | NAT uatwebcall / vcall | P | [2N] |
| 10.179.10.99 / .101 | RNET-01 / 02 | M | [2N] |
| 10.179.11.101 / .102 | Loopback A-CCX (NAT) | A | [1N] |
| 10.179.20.234 | ExtSW (stack) | M | [2N] |
| 10.179.20.123 | FG external (default route của ExtSW) | G | [1N] |
| 10.179.70.11 / .12 | VoiceGW | M | [2N] |
| 172.31.70.11 | VoiceGW 03 (PCCE3) | M | [1N] |
| 10.179.110.5 / .6 | SAN switch | M | [2N] |
| 10.179.110.9 | Unity300 | M | [2N] |
| 10.179.110.10 | vCenter | M | [1N] |
| 10.179.110.20 | IntSW stack | M | [2N] |
| 10.179.110.21 – .26 | ESXi A-App | M | [2N] |
| 10.179.110.121 (.21) / .122 (.22) / .158 (.23) / .124 (.24) / .125 (.25) / .126 (.26) | iDRAC9 A-App (xác minh Redfish 2026-11-26; .121 web treo) | B | [Live] |
| 10.179.110.45 / .47 | ESXi PCCE3-A / B | M | [2N] |
| 10.179.110.46 / .48 | CIMC PCCE3-A / B | B | [1N] |
| 10.179.110.53 | ESXi A-CCX | M | [2N] |
| 10.179.110.155 | BMC A-CCX | B | [1N] |
| 10.179.110.51 / .52 / .54 | PCCE01 / 02 / CCX02 theo DeviceList 2023 — nhiều khả năng đã gỡ | — | [1N] |
| 10.179.120.20 | AD / DNS CN247 | A | [1N] |
| 10.179.249.90 / .91 | FG01 / FG02 | M | [2N] |
| 10.179.80.5 / .6 | NFS / SMB backup | A | [1N] |
| 172.31.253.51 | DNS VTB PROD | A | [1N] |
| 172.31.184.56 | DB RemoteGW pcce3 | A | [1N] |
| 172.31.183.64 | vcall | A | [2N] |
| 172.31.245.1 / .20 / .78 / .94 | GW / AD / webcall UAT | A | [2N] |

## E. FHN02 — Phạm Văn Bạch (10.199.x)

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 58.186.204.24/29 | Public (.25 dc1-api, .26 portal, .27 SIP) | P | [2N] |
| 10.199.10.x / 10.199.249.x | RNET / FG (nhãn rack bị cắt) | M | [1N] |
| 10.199.20.234 / 10.199.110.20 | ExtSW / IntSW (chỉ x05) | M | [1N] |
| 10.199.20.123 | FG external (next-hop route VSG.VPN) | G | [1N] |
| 10.199.70.11 / .12 | VoiceGW | M | [1N] rack |
| 10.199.110.5 / .6 | SAN switch | M | [2N] |
| 10.199.110.9 | Unity380 | M | [2N] |
| 10.199.110.10 | vCenter | M | [1N] |
| 10.199.110.21 / .22 / .23 | ESXi AppSvrs | M | [2N] |
| 10.199.110.121 – .123 | BMC | B | [1N] |
| 10.199.110.200 | NAS VM (IP phụ 10.199.80.200) | A | [1N] |
| 10.199.120.20 | AD hn02basebs.com | A | [2N] |
| 10.199.90.25 | DB RemoteGW | A | [1N] |
| 10.199.184.70 / .71 / .80 / .85 | SIP / SIP / dc1-api / portal | A | [2N] |
| 192.168.100.41 / .42 / .49 / .51 | Transit Metro HDSS (CMC / FPT) | G | [1N] x05 |

## F. SG03, cloud, văn phòng

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 42.119.139.16 / .17 | contactcenter / expressway → 10.148.184.50 / .55 | P | [2N] |
| 10.148.11.101 / .102 | Loopback sg03 trên RNET-02 | A | [1N] |
| 10.148.120.20 | PDC SG03 | A | [1N] |
| 167.254.73.126 | FPT Cloud FGT WAN (VIP :13389 RDP, :80 / :443 APISIX) | P | [2N] |
| 10.1.0.1 / .2 / .65 | FGT MGMT / JumpHost / peering | M | [2N] |
| 10.60.4.25 | APISIX | A | [2N] |
| 10.99.99.100 – .200 / 172.29.29.0/24 | Pool dial-up VPN / SSL-VPN cloud | — | [1N] CONF |
| 192.168.{70,90,120,182,184,188}.254 | pfSense CMC (Heineken) | G | [1N] |
| 192.168.6.1 / 192.168.7.1 | REE LAN / next-hop | G | [1N] x05 |
| 10.0.80.1 / .20 | REE router 2911 / C2960X (x05) | M | [1N] |
| 14.177.234.235 / 10.29.30.0/24 | HN Office | P / A | [1N] |
| 10.89.89.10 – .20 | Pool VPN admin "FSG2.VPN-Admins", được phép vào MGT VDC | — | [1N] x06 |
| 10.69.68.0/24 | "VSG.VPN" (pool VPN; có host thử SSH .8) | — | [SL] |

## G. Bổ sung 24/11 (BG_Maintain, x09, x08)

| IP | Thiết bị | Loại | Nhãn |
|---|---|---|---|
| 10.179.10.102 | FHN01 NET.RouterNET.02 ISR4331-SEC (DeviceList ghi .101) | M | [1N] BG |
| 10.199.10.101 / .102 | FHN02 RouterNET.01 / 02 C8300-SEC | M | [1N] BG |
| 10.199.249.90 / .91 | FHN02 FW01 / FW02 | M | [2N] BG + rack |
| 10.127.109.2 | FSG01 Router MPLS Cisco 2911 (DeviceList ghi .129.2) | M | [2N] BG + rack |
| 10.138.173.56 / 10.138.70.11 | FSG01 VoiceGW.03 / .04 C8200-1N-4T | M | [2N] BG + rack |
| 10.189.110.1 | SMB NET.Firewall.01/02 (1 serial) | M/G | [1N] BG |
| 10.199.80.200 | nassvr.hn02basebs.com (NAS backup) | A | [1N] x08 |
| 10.179.120.5 / .6 | Backup VTB NFS / SMB | A | [1N] x08 |
| 10.138.180.200 | FDC.NAS01 / backup SG02 | A | [2N] x08 + x06 |
| 10.169.120.9 | Share backup VDC (mâu thuẫn K31 với .6) | A | [1N] |
| 10.169.120.5 | NFS Intranet backup | A | [1N] |
| 192.168.182.52 / .51 / .61 | CMC: aiapp01 / ssoapp01 / ssoelastic | A | [1N] x09 |
| 192.168.90.52 / .51 | CMC: aidb01 / mongodb01 | A | [1N] x09 |
| 192.168.184.51 | CMC: proxy01 | A | [1N] x09 |
| 192.168.188.51 / .52 | CMC: lcmapp01 / vportal01 | A | [1N] x09 |
| 192.168.70.11 | CMC: voicegw01 | M | [1N] x09 |
| 192.168.120.55 | CMC: Monitoring | A | [1N] x09 |
