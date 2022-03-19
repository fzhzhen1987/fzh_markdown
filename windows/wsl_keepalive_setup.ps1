# 让 WSL 不会在空闲时自动关闭（登记到任务计划程序）
#
# 用法（普通 PowerShell 执行，不需要管理员。只要执行一次）:
#   pwsh -ExecutionPolicy Bypass -File wsl_keepalive_setup.ps1
#   pwsh -ExecutionPolicy Bypass -File wsl_keepalive_setup.ps1 -Distro Ubuntu-22.04
#
# 原理:
#   登录 Windows 时，在 WSL 里启动一个不会结束的进程（sleep infinity）。
#   WSL 认为 Windows 这边一直有进程在用它，就不会自动关闭。
#   用 conhost --headless 启动，所以不会弹出窗口。
#
# 取消: wsl_keepalive_remove.ps1

param(
    [string]$Distro   = 'Ubuntu-22.04',
    [string]$TaskName = 'WSL-KeepAlive'
)

$ErrorActionPreference = 'Stop'

$action    = New-ScheduledTaskAction -Execute 'conhost.exe' `
               -Argument "--headless wsl.exe -d $Distro --exec sleep infinity"
$trigger   = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$settings  = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
               -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName

Start-Sleep -Seconds 15
$state = (Get-ScheduledTask -TaskName $TaskName).State
$wsl   = ((wsl.exe -l -v | Out-String) -replace "`0", '')

Write-Host "Task '$TaskName' state: $state"
Write-Host $wsl
if ($state -eq 'Running' -and $wsl -match "$Distro\s+Running") {
    Write-Host 'OK: WSL is kept running.'
} else {
    Write-Host 'NG: task or WSL is not running.'
    exit 1
}
