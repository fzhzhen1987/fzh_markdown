# 停止并删除 wsl_keepalive_setup.ps1 登记的任务（WSL 恢复成空闲时会自动关闭）
#
# 用法:
#   pwsh -ExecutionPolicy Bypass -File wsl_keepalive_remove.ps1

param(
    [string]$TaskName = 'WSL-KeepAlive'
)

if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
    Write-Host "Task '$TaskName' not found. Nothing to do."
    exit 0
}

Stop-ScheduledTask -TaskName $TaskName
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

# 停了任务，sleep infinity 有时还会留着，这里把它结束掉
Get-CimInstance Win32_Process -Filter "Name='wsl.exe'" |
    Where-Object CommandLine -match 'sleep infinity' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Write-Host "Task '$TaskName' removed."
