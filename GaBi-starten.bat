@echo off
setlocal
title GaBi bei Dirk starten
cd /d "%~dp0spiel"
if errorlevel 1 goto :folder_error

where docker >nul 2>&1
if errorlevel 1 (
    echo Docker wurde nicht gefunden. Bitte Docker Desktop installieren und starten.
    pause
    exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
    echo Docker ist noch nicht bereit. Bitte Docker Desktop starten und erneut versuchen.
    pause
    exit /b 1
)

if not exist "..\godot\build\index.html" (
    echo Der Godot-Webexport fehlt. Bitte zuerst godot\build-web.ps1 ausfuehren.
    pause
    exit /b 1
)

echo GaBi wird gestartet ...
docker compose up -d --build --wait --wait-timeout 90
if errorlevel 1 (
    echo.
    echo Das Spiel konnte nicht gestartet werden. Die Fehlermeldung steht oben.
    pause
    exit /b 1
)

if not defined GAME_PORT set "GAME_PORT=8085"
echo.
echo GaBi laeuft auf http://localhost:%GAME_PORT%
start "" "http://localhost:%GAME_PORT%"
exit /b 0

:folder_error
echo Der Spielordner wurde nicht gefunden. Die Batch-Datei bitte im Projektordner lassen.
pause
exit /b 1
