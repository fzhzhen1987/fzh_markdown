#Requires -Version 7
# wt-apply-keys.ps1 — 把同一文件夹里 wt-keys.json 的 actions・keybindings 覆盖到 Windows Terminal 的 settings.json
#
# 用法（PowerShell 7，在本文件所在的文件夹执行）：
#   pwsh -File .\wt-apply-keys.ps1
#
# 只换 actions・keybindings 两块，其他设置（profiles・defaultProfile・配色等每台电脑自己的）原样保留。
# 不备份：这台电脑上自己临时加的快捷键会被 wt-keys.json 的内容覆盖掉。
# Windows Terminal 开着也可以，它发现文件变了会自动重新读取。
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'wt-keys.json'

# settings.json 的位置：Microsoft Store 版 → 其他安装方式（scoop・winget 的免安装版）
$candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)
$dst = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $dst) {
    throw "没找到 Windows Terminal 的 settings.json。先打开一次 Windows Terminal（第一次打开时才会生成这个文件）。"
}

$keys = Get-Content $src -Raw -Encoding utf8 | ConvertFrom-Json
$settings = Get-Content $dst -Raw -Encoding utf8 | ConvertFrom-Json

$settings | Add-Member -Force -NotePropertyName actions -NotePropertyValue $keys.actions
$settings | Add-Member -Force -NotePropertyName keybindings -NotePropertyValue $keys.keybindings

# -Depth：PowerShell 默认只写 2 层，keybindings 比 2 层深，不加的话深处会被写成字符串
$settings | ConvertTo-Json -Depth 100 | Set-Content $dst -Encoding utf8NoBOM

Write-Host ("已覆盖：{0}（actions {1} 条、keybindings {2} 条）" -f $dst, $keys.actions.Count, $keys.keybindings.Count)
