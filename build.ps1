# Builds a patched GraphicsAssets.swf with the bot injected (needs JPEXS FFDec + Java).
# Usage: .\build.ps1 -GameDir "D:\OfflineGames\Governor.of.Poker.2" [-Install]
param([Parameter(Mandatory)][string]$GameDir, [switch]$Install,
      [string]$Ffdec = "D:\Program Files (x86)\FFDec\ffdec-cli.exe")
$ErrorActionPreference = "Stop"
$w = Join-Path $env:TEMP "gop2-bot-build"; Remove-Item $w -Recurse -Force -EA SilentlyContinue; New-Item -ItemType Directory $w | Out-Null
$orig = Join-Path $GameDir "GraphicsAssets.swf.orig"
if (-not (Test-Path $orig)) { Copy-Item (Join-Path $GameDir "GraphicsAssets.swf") $orig }   # keep the untouched original
Copy-Item $orig "$w\orig.swf"
& $Ffdec -cli -export script "$w\scripts_out" "$w\orig.swf" | Out-Null
$d = "$w\scripts_out\scripts\frame_3\DoAction.as"
$code = (Get-Content $d -Raw -Encoding UTF8).TrimEnd() + "`r`n" + (Get-Content "$PSScriptRoot\src\botcore.as" -Raw -Encoding UTF8) + "`r`n" + (Get-Content "$PSScriptRoot\src\botglue.as" -Raw -Encoding UTF8)
[IO.File]::WriteAllText($d, $code, (New-Object Text.UTF8Encoding $false))
& $Ffdec -cli -importScript "$w\orig.swf" "$w\patched.swf" "$w\scripts_out\scripts"
if (-not (Test-Path "$w\patched.swf")) { throw "Build failed - game folder left unchanged" }
if ($Install) { Copy-Item "$w\patched.swf" (Join-Path $GameDir "GraphicsAssets.swf") -Force; "Installed. Restart the game." } else { "Built: $w\patched.swf" }
