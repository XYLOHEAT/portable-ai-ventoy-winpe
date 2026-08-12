@echo off
title Initialize WinPE Network
echo Initializing the WinPE network stack...
if exist "%SystemRoot%\System32\wpeutil.exe" wpeutil InitializeNetwork
if exist "%SystemRoot%\System32\wpeinit.exe" wpeinit
echo.
ipconfig
echo.
echo If no adapter appears, use the WinPE network utility and load the NIC driver.
pause
