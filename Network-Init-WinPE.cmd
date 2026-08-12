@echo off
title Initialize WinPE Network
echo Initializing the WinPE network stack...
if exist "%SystemRoot%\System32\wpeutil.exe" wpeutil InitializeNetwork
if exist "%SystemRoot%\System32\wpeinit.exe" wpeinit
echo.
ipconfig
echo.
echo If no adapter appears, use Sergei Strelec PENetwork and load the NIC driver.
pause
