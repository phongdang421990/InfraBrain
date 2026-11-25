<#
.SYNOPSIS
  Health check READ-ONLY cho vCenter/ESXi. Không thay đổi bất kỳ cấu hình nào.
.EXAMPLE
  .\Invoke-VSphereHealthCheck.ps1 -VCenter vcenter.fdc.local
#>
param(
    [Parameter(Mandatory = $true)][string]$VCenter,
    [string]$OutDir = (Join-Path $PSScriptRoot "..\..\..\..\90-Raw\healthcheck"),
    [int]$SnapshotDays = 7
)

$ErrorActionPreference = 'Stop'
Import-Module VMware.VimAutomation.Core

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$dir = Join-Path $OutDir ("{0}_{1}" -f $VCenter, $stamp)
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# Credential do người dùng tự nhập, dùng tài khoản Read-only
$cred = Get-Credential -Message "Tai khoan READ-ONLY cho $VCenter"
Connect-VIServer -Server $VCenter -Credential $cred | Out-Null

function Get-Pct($used, $total) {
    if ($total -gt 0) { [math]::Round($used / $total * 100, 1) } else { $null }
}

try {
    # 1. Host
    $hosts = Get-VMHost | Select-Object Name,
        @{N = 'Cluster'; E = { $_.Parent.Name } },
        ConnectionState, PowerState, Version, Build, Model,
        @{N = 'OverallStatus'; E = { $_.ExtensionData.OverallStatus } },
        @{N = 'CpuUsagePct'; E = { Get-Pct $_.CpuUsageMhz $_.CpuTotalMhz } },
        @{N = 'MemUsagePct'; E = { Get-Pct $_.MemoryUsageGB $_.MemoryTotalGB } },
        @{N = 'MemTotalGB'; E = { [math]::Round($_.MemoryTotalGB, 0) } },
        @{N = 'UptimeDays'; E = { [math]::Round($_.ExtensionData.Summary.QuickStats.Uptime / 86400, 0) } }
    $hosts | Export-Csv (Join-Path $dir 'hosts.csv') -NoTypeInformation -Encoding UTF8

    # 2. Cluster
    $clusters = Get-Cluster | Select-Object Name, HAEnabled, HAAdmissionControlEnabled,
        DrsEnabled, DrsAutomationLevel,
        @{N = 'HostCount'; E = { @($_ | Get-VMHost).Count } }
    $clusters | Export-Csv (Join-Path $dir 'clusters.csv') -NoTypeInformation -Encoding UTF8

    # 3. Datastore
    $ds = Get-Datastore | Select-Object Name, Type, State,
        @{N = 'CapacityGB'; E = { [math]::Round($_.CapacityGB, 0) } },
        @{N = 'FreeGB'; E = { [math]::Round($_.FreeSpaceGB, 0) } },
        @{N = 'UsedPct'; E = { Get-Pct ($_.CapacityGB - $_.FreeSpaceGB) $_.CapacityGB } },
        @{N = 'Accessible'; E = { $_.ExtensionData.Summary.Accessible } }
    $ds | Export-Csv (Join-Path $dir 'datastores.csv') -NoTypeInformation -Encoding UTF8

    # 4. VM
    $vms = Get-VM
    $vms | Select-Object Name, PowerState, NumCpu, MemoryGB,
        @{N = 'Host'; E = { $_.VMHost.Name } },
        @{N = 'ToolsRunning'; E = { $_.ExtensionData.Guest.ToolsRunningStatus } },
        @{N = 'OverallStatus'; E = { $_.ExtensionData.OverallStatus } } |
        Export-Csv (Join-Path $dir 'vms.csv') -NoTypeInformation -Encoding UTF8

    # 5. Snapshot cũ
    $limit = (Get-Date).AddDays(-$SnapshotDays)
    $snaps = $vms | Get-Snapshot | Where-Object { $_.Created -lt $limit } |
        Select-Object VM, Name, Created, @{N = 'SizeGB'; E = { [math]::Round($_.SizeGB, 1) } }
    $snaps | Export-Csv (Join-Path $dir 'snapshots-old.csv') -NoTypeInformation -Encoding UTF8

    # 6. Triggered alarms
    $alarms = foreach ($type in 'HostSystem', 'VirtualMachine', 'Datastore', 'ClusterComputeResource') {
        foreach ($e in (Get-View -ViewType $type -Property Name, TriggeredAlarmState)) {
            foreach ($a in $e.TriggeredAlarmState) {
                $def = Get-View $a.Alarm -Property Info
                [pscustomobject]@{
                    EntityType   = $type
                    Entity       = $e.Name
                    Alarm        = $def.Info.Name
                    Status       = $a.OverallStatus
                    Time         = $a.Time
                    Acknowledged = $a.Acknowledged
                }
            }
        }
    }
    $alarms | Export-Csv (Join-Path $dir 'alarms.csv') -NoTypeInformation -Encoding UTF8

    Write-Host ""
    Write-Host "=== Tom tat $VCenter ===" -ForegroundColor Cyan
    Write-Host ("Host: {0} | Khong Connected: {1}" -f @($hosts).Count, @($hosts | Where-Object ConnectionState -ne 'Connected').Count)
    Write-Host ("Cluster HA tat: {0}" -f @($clusters | Where-Object { -not $_.HAEnabled }).Count)
    Write-Host ("Datastore >= 80%: {0}" -f @($ds | Where-Object { $_.UsedPct -ge 80 }).Count)
    Write-Host ("Snapshot > {0} ngay: {1}" -f $SnapshotDays, @($snaps).Count)
    Write-Host ("Alarm dang bat: {0}" -f @($alarms).Count)
    Write-Host "Ket qua: $dir" -ForegroundColor Green
}
finally {
    Disconnect-VIServer -Server $VCenter -Confirm:$false
}
