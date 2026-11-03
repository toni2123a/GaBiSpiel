param([string]$GodotPath = "$PSScriptRoot\..\tools\godot\Godot_v4.7.2-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force "$PSScriptRoot\build" | Out-Null
& $GodotPath --headless --editor --path $PSScriptRoot --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot-Import fehlgeschlagen' }
$validation = & $GodotPath --headless --path $PSScriptRoot --quit-after 5 2>&1
$validation | Write-Output
if ($LASTEXITCODE -ne 0 -or ($validation -join "`n") -match '(?m)^(SCRIPT ERROR:|ERROR:)') { throw 'Godot-Laufzeitprüfung fehlgeschlagen' }
& $GodotPath --headless --path $PSScriptRoot --export-release Web "$PSScriptRoot\build\index.html"
if ($LASTEXITCODE -ne 0) { throw 'Godot-Webexport fehlgeschlagen' }
