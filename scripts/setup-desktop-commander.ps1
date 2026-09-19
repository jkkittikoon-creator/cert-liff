$ErrorActionPreference = 'Stop'
$root = 'D:\AI-Stack'
$cfg  = "$env:USERPROFILE\.claude-server-commander\config.json"
if (-not (Test-Path $root)) { throw "Not found: $root" }
if (-not (Test-Path $cfg))  { throw "Config not found: $cfg" }

$old = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'node.exe' -and $_.CommandLine -like '*desktop-commander*' }
if ($old) { $old | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; Start-Sleep 2; "Stopped: $($old.ProcessId -join ', ')" }

$backup = "$cfg.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $cfg $backup; "Backup: $backup"

if ($PSVersionTable.PSVersion.Major -le 5) { Remove-TypeData System.Array -ErrorAction SilentlyContinue }
$j = Get-Content $cfg -Raw -Encoding UTF8 | ConvertFrom-Json
[string[]]$dirs = @($root)
if ($j.PSObject.Properties.Name -contains 'allowedDirectories') { $j.allowedDirectories = $dirs }
else { $j | Add-Member -NotePropertyName allowedDirectories -NotePropertyValue $dirs }
[System.IO.File]::WriteAllText($cfg, ($j | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding($false)))

$raw = Get-Content $cfg -Raw -Encoding UTF8
if ($raw -match '"Count"\s*:') { Copy-Item $backup $cfg -Force; throw "Bad JSON - restored backup" }
"allowedDirectories:"; ($raw | ConvertFrom-Json).allowedDirectories

Start-Process npx.cmd -ArgumentList '@wonderwhy-er/desktop-commander@latest','remote' `
  -WorkingDirectory $root -WindowStyle Hidden `
  -RedirectStandardOutput "$root\dc-remote.log" -RedirectStandardError "$root\dc-remote.err"
"Remote started in background"
