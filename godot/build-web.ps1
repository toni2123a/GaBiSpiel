param([string]$GodotPath = "$PSScriptRoot\..\tools\godot\Godot_v4.7.2-stable_win64_console.exe")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force "$PSScriptRoot\build" | Out-Null
& $GodotPath --headless --editor --path $PSScriptRoot --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot-Import fehlgeschlagen' }
& $GodotPath --headless --path $PSScriptRoot --export-release Web "$PSScriptRoot\build\index.html"
if ($LASTEXITCODE -ne 0) { throw 'Godot-Webexport fehlgeschlagen' }
