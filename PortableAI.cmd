@echo off
setlocal EnableExtensions
title Portable AI for Ventoy WinPE

set "PAI_ROOT=%~dp0"
set "PAI_HOME=%PAI_ROOT%data\home"
set "CODEX_HOME=%PAI_ROOT%data\codex"
set "CLAUDE_CONFIG_DIR=%PAI_ROOT%data\claude"
set "USERPROFILE=%PAI_HOME%"
set "HOME=%PAI_HOME%"
set "APPDATA=%PAI_HOME%\AppData\Roaming"
set "LOCALAPPDATA=%PAI_HOME%\AppData\Local"
set "DISABLE_AUTOUPDATER=1"
set "DISABLE_UPDATES=1"
set "CLAUDE_CODE_USE_POWERSHELL_TOOL=1"
set "PATH=%PAI_ROOT%apps\codex\codex-path;%PAI_ROOT%apps\codex\codex-resources;%PATH%"

if not exist "%PAI_HOME%" mkdir "%PAI_HOME%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%CODEX_HOME%" mkdir "%CODEX_HOME%"
if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"
if not exist "%PAI_ROOT%workspaces" mkdir "%PAI_ROOT%workspaces"

set "CODEX_EXE=%PAI_ROOT%apps\codex\bin\codex.exe"
set "CLAUDE_EXE=%PAI_ROOT%apps\claude\claude.exe"

:menu
cls
echo ================================================================
echo   Portable AI - Ventoy / WinPE x64
echo ================================================================
echo.
echo WARNING: WinPE can access every mounted disk. Review every command.
echo Claude native Windows has no OS sandbox. Codex EDIT disables sandbox.
echo.
echo   1. Codex SAFE       ^(read-only, approvals on^)
echo   2. Codex EDIT       ^(can write/run after approval^)
echo   3. Claude PLAN      ^(read/analyze only^)
echo   4. Claude MANUAL    ^(can edit/run after approval^)
echo   5. Codex login      ^(device code^)
echo   6. Claude login
echo   7. Diagnostics
echo   8. Logout both accounts
echo   9. Exit
echo.
set "CHOICE="
set /p "CHOICE=Select [1-9]: "

if "%CHOICE%"=="1" goto workspace_codex_safe
if "%CHOICE%"=="2" goto workspace_codex_edit
if "%CHOICE%"=="3" goto workspace_claude_plan
if "%CHOICE%"=="4" goto workspace_claude_manual
if "%CHOICE%"=="5" goto codex_login
if "%CHOICE%"=="6" goto claude_login
if "%CHOICE%"=="7" goto diagnostics
if "%CHOICE%"=="8" goto logout
if "%CHOICE%"=="9" exit /b 0
goto menu

:choose_workspace
set "WORKSPACE="
echo.
echo Enter a workspace path, for example D:\project
echo Press Enter to use: %PAI_ROOT%workspaces
set /p "WORKSPACE=Workspace: "
if not defined WORKSPACE set "WORKSPACE=%PAI_ROOT%workspaces"
if not exist "%WORKSPACE%" (
  echo.
  echo Folder not found: %WORKSPACE%
  pause
  exit /b 1
)
cd /d "%WORKSPACE%"
exit /b 0

:workspace_codex_safe
if not exist "%CODEX_EXE%" goto missing_codex
call :choose_workspace
if errorlevel 1 goto menu
"%CODEX_EXE%" -s read-only -a untrusted --no-alt-screen
pause
goto menu

:workspace_codex_edit
if not exist "%CODEX_EXE%" goto missing_codex
call :choose_workspace
if errorlevel 1 goto menu
echo.
echo EDIT mode has direct access to mounted disks. Approve carefully.
pause
"%CODEX_EXE%" -s danger-full-access -a untrusted --no-alt-screen
pause
goto menu

:workspace_claude_plan
if not exist "%CLAUDE_EXE%" goto missing_claude
call :choose_workspace
if errorlevel 1 goto menu
"%CLAUDE_EXE%" --permission-mode plan
pause
goto menu

:workspace_claude_manual
if not exist "%CLAUDE_EXE%" goto missing_claude
call :choose_workspace
if errorlevel 1 goto menu
echo.
echo MANUAL mode has no OS sandbox on native Windows. Approve carefully.
pause
"%CLAUDE_EXE%" --permission-mode manual
pause
goto menu

:codex_login
if not exist "%CODEX_EXE%" goto missing_codex
"%CODEX_EXE%" login --device-auth
pause
goto menu

:claude_login
if not exist "%CLAUDE_EXE%" goto missing_claude
"%CLAUDE_EXE%" auth login
pause
goto menu

:diagnostics
echo.
echo Architecture: %PROCESSOR_ARCHITECTURE%
echo Root: %PAI_ROOT%
echo.
where powershell.exe 2>nul
where curl.exe 2>nul
where tar.exe 2>nul
echo.
if exist "%CODEX_EXE%" "%CODEX_EXE%" --version
if exist "%CLAUDE_EXE%" "%CLAUDE_EXE%" --version
echo.
ipconfig
pause
goto menu

:logout
if exist "%CODEX_EXE%" "%CODEX_EXE%" logout
if exist "%CLAUDE_EXE%" "%CLAUDE_EXE%" auth logout
echo Account tokens were removed by each CLI from the portable profile.
pause
goto menu

:missing_codex
echo.
echo Codex binary is missing. Run Update-PortableAI.cmd on full Windows.
pause
goto menu

:missing_claude
echo.
echo Claude binary is missing. Run Update-PortableAI.cmd on full Windows.
pause
goto menu
