# CR 2026-11-24-quarantine-credential-files: bước 1 (Đăng tự chạy).
# Chuyển 12 file credential từ 00-Inbox\Base ra thư mục quarantine NGOÀI vault.
# Script chỉ dùng Move-Item, KHÔNG xóa file. Hash được kiểm tra trước và sau khi chuyển.
# Nếu đích đã có file trùng tên, script dừng trước khi chuyển bất kỳ file nào.
# Rollback: chạy lại script với tham số -Rollback (chuyển ngược về chỗ cũ, cũng kiểm tra hash).
param([switch]$Rollback)
$ErrorActionPreference = 'Stop'
$src = 'C:\Users\Dang Tran\Documents\InfraBrain\00-Inbox\Base'
$dst = 'C:\Users\Dang Tran\Documents\BaseBS-Secrets-Quarantine'
# Đường dẫn tương đối (dưới $src / $dst) -> 16 ký tự đầu của SHA-256 ghi trong CR
$files = [ordered]@{
  'Base-Passwork-AllDC.xlsx'                                = 'EB51EEAE4AD240C2'
  'Base-Passwork-AllDC-remove pasword.xlsx'                 = '5791076CBBEB3C5E'
  'NoiBo1-Infra-Credential.xlsx'                            = '6FF6677E15041B83'
  'NoiBo1-Infras-System Hardware Credentials.xlsx'          = 'DE6ECE419D4F005C'
  'NoiBo1-Infras-System RemoteGW.xlsx'                      = '0A5CC58F24988A01'
  'Nội Bộ 2 - Heineken - AICC-NoiBo2 _  Credentials.xlsx'  = '67D1D8EA4BF17F36'
  'NoiBo2- System Transfer -Tin.xlsx'                       = 'C1492FD0FC6D836A'
  'FTP Cloud (1).zip'                                       = '8601444F1AC319C7'
  'Infra\Base-Password-DangTP.xlsx'                         = '02E7943F13DE1582'
  'Infra\Base-Passwork-System Infra.xlsx'                   = '51291D919A1DFA47'
  'Infra\NoiBo1-Infra-Credential.xlsx'                      = '62B2A002C93FAFC3'
  'Keepass Network\VinhLQ-network.kdbx'                     = '47A9C3182CE1ACC4'
}
$from = if ($Rollback) { $dst } else { $src }
$to   = if ($Rollback) { $src } else { $dst }

# Pre-flight: kiểm tra TẤT CẢ trước khi chuyển bất kỳ file nào
foreach ($rel in $files.Keys) {
  $s = Join-Path $from $rel; $d = Join-Path $to $rel
  if (-not (Test-Path -LiteralPath $s)) { throw "MISSING source: $rel" }
  $h = (Get-FileHash -LiteralPath $s -Algorithm SHA256).Hash.Substring(0,16)
  if ($h -ne $files[$rel]) { throw "HASH MISMATCH before move: $rel ($h)" }
  if (Test-Path -LiteralPath $d) { throw "DESTINATION EXISTS, refusing to overwrite: $d" }
}

$ok = 0
foreach ($rel in $files.Keys) {
  $s = Join-Path $from $rel; $d = Join-Path $to $rel
  New-Item -ItemType Directory -Force -Path (Split-Path $d) | Out-Null
  Move-Item -LiteralPath $s -Destination $d
  $h = (Get-FileHash -LiteralPath $d -Algorithm SHA256).Hash.Substring(0,16)
  if ($h -ne $files[$rel]) { throw "HASH MISMATCH after move: $rel ($h)" }
  "MOVED  $rel  $h"; $ok++
}
"OK $ok/$($files.Count)  ->  $to"
