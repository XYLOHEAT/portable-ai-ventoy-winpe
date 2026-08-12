@echo off
setlocal
title Update Portable AI
echo Run this updater on full Windows 10/11 with internet access.
echo It downloads only from official vendor release servers and verifies SHA-256.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-PortableAI.ps1" %*
echo.
pause
