@echo off
setlocal
title Update Portable AI
echo Run this updater on full Windows 10/11 with internet access.
echo It downloads only from official OpenAI and Anthropic release servers.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-PortableAI.ps1"
echo.
pause
