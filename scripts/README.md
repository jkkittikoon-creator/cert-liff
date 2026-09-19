# scripts

## setup-desktop-commander.ps1

Windows-only helper (run on the local machine, not in CI or a remote session).

Points Desktop Commander's `allowedDirectories` at `D:\AI-Stack` and restarts
the remote server in the background.

What it does:

1. Stops any running `node.exe` process whose command line mentions
   `desktop-commander`.
2. Backs up `%USERPROFILE%\.claude-server-commander\config.json` to a
   timestamped `.bak-<yyyyMMdd-HHmmss>` file.
3. Rewrites `allowedDirectories` to `["D:\\AI-Stack"]` (UTF-8, no BOM).
4. Restores the backup and aborts if the result contains a stray `"Count"` key
   (a PowerShell 5.1 `ConvertTo-Json` artifact when serializing arrays).
5. Starts `npx @wonderwhy-er/desktop-commander@latest remote` hidden, with
   stdout to `D:\AI-Stack\dc-remote.log` and stderr to `D:\AI-Stack\dc-remote.err`.

### Run

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\AI-Stack\setup-desktop-commander.ps1
```

### Verify

```powershell
Start-Sleep 20
"===== dc-remote.log ====="; Get-Content 'D:\AI-Stack\dc-remote.log' -Raw -ErrorAction SilentlyContinue
"===== dc-remote.err ====="; Get-Content 'D:\AI-Stack\dc-remote.err' -Raw -ErrorAction SilentlyContinue
"===== config ====="
$cfg = "$env:USERPROFILE\.claude-server-commander\config.json"
$raw = Get-Content $cfg -Raw -Encoding UTF8
$raw
"--- parsed allowedDirectories ---"
$d = (ConvertFrom-Json $raw).allowedDirectories
$d | ForEach-Object { $_ }
"count = $(@($d).Count); isArray = $($d -is [array]); hasCountKey = $([bool]($raw -match '"Count"\s*:'))"
"===== process ====="
Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*desktop-commander*' } | Select-Object ProcessId, CommandLine | Format-List
```

The config is correct when `allowedDirectories` parses as a JSON array
`["D:\\AI-Stack"]` with `count = 1`, `isArray = True`, `hasCountKey = False`.

### Known failure modes

- `allowedDirectories` serialized as a bare string instead of a one-element
  array — write the JSON directly instead of going through `ConvertTo-Json`.
- `npx.cmd` not on `PATH` — `Start-Process` throws immediately; check
  `dc-remote.err`.
- Both log files empty and no `node.exe` running — the server exited during
  startup; `dc-remote.err` has the reason.
