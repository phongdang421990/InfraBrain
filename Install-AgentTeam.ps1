<#
  Cai doi agent + skill vao .claude cua vault InfraBrain.
  Chay: powershell -ExecutionPolicy Bypass -File .\Install-AgentTeam.ps1
  Script chi copy file trong _setup\claude sang .claude, khong lam gi khac.
#>
$root = $PSScriptRoot
$src  = Join-Path $root '_setup\claude'
$dst  = Join-Path $root '.claude'
if (-not (Test-Path $src)) { Write-Error "Khong tim thay $src"; exit 1 }
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item -Path (Join-Path $src '*') -Destination $dst -Recurse -Force
# Don file kiem tra do Claude lo tao (2026-11-27)
Remove-Item (Join-Path $dst 'agents\_writetest') -ErrorAction SilentlyContinue
Write-Host "Da cai vao $dst :" -ForegroundColor Green
Get-ChildItem $dst -Recurse -File | ForEach-Object { '  ' + $_.FullName.Substring($dst.Length + 1) }
Write-Host ""
Write-Host "Tiep theo: cd `"$root`"; claude   roi go /agents" -ForegroundColor Cyan
