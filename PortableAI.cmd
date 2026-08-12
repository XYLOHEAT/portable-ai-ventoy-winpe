@echo off
setlocal EnableExtensions
title Portable AI for Ventoy WinPE

set "PAI_ROOT=%~dp0"
set "PAI_HOME=%PAI_ROOT%data\home"
set "CODEX_HOME=%PAI_ROOT%data\codex"
set "CLAUDE_CONFIG_DIR=%PAI_ROOT%data\claude"
set "OPENCODE_CONFIG_DIR=%PAI_ROOT%data\opencode\config"
set "CRUSH_GLOBAL_CONFIG=%PAI_ROOT%data\crush\crush.json"
set "CRUSH_GLOBAL_DATA=%PAI_ROOT%data\crush\data"
set "GOOSE_PATH_ROOT=%PAI_ROOT%data\goose"
set "USERPROFILE=%PAI_HOME%"
set "HOME=%PAI_HOME%"
set "APPDATA=%PAI_HOME%\AppData\Roaming"
set "LOCALAPPDATA=%PAI_HOME%\AppData\Local"
set "DISABLE_AUTOUPDATER=1"
set "DISABLE_UPDATES=1"
set "CLAUDE_CODE_USE_POWERSHELL_TOOL=1"
set "OPENCODE_DISABLE_AUTOUPDATE=1"
set "CRUSH_DISABLE_METRICS=1"
set "DO_NOT_TRACK=1"
set "PATH=%PAI_ROOT%apps\mingit\cmd;%PAI_ROOT%apps\opencode;%PAI_ROOT%apps\crush;%PAI_ROOT%apps\goose;%PAI_ROOT%apps\codex\codex-path;%PAI_ROOT%apps\codex\codex-resources;%PATH%"

if not exist "%PAI_HOME%" mkdir "%PAI_HOME%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%CODEX_HOME%" mkdir "%CODEX_HOME%"
if not exist "%CLAUDE_CONFIG_DIR%" mkdir "%CLAUDE_CONFIG_DIR%"
if not exist "%OPENCODE_CONFIG_DIR%" mkdir "%OPENCODE_CONFIG_DIR%"
if not exist "%PAI_ROOT%data\crush\data" mkdir "%PAI_ROOT%data\crush\data"
if not exist "%GOOSE_PATH_ROOT%" mkdir "%GOOSE_PATH_ROOT%"
if not exist "%PAI_ROOT%workspaces" mkdir "%PAI_ROOT%workspaces"

set "CODEX_EXE=%PAI_ROOT%apps\codex\bin\codex.exe"
set "CLAUDE_EXE=%PAI_ROOT%apps\claude\claude.exe"
set "OPENCODE_EXE=%PAI_ROOT%apps\opencode\opencode.exe"
set "CRUSH_EXE=%PAI_ROOT%apps\crush\crush.exe"
set "GOOSE_EXE=%PAI_ROOT%apps\goose\goose.exe"

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
echo   5. OpenCode PLAN    ^(read/analyze; shell asks^)
echo   6. OpenCode BUILD   ^(can edit/run with permissions^)
echo   7. Crush ASK        ^(multi-model; permission prompts^)
echo   8. Goose SESSION    ^(multi-model; direct disk access^)
echo   9. Accounts / provider setup
echo   D. Diagnostics
echo   Q. Exit
echo.
set "CHOICE="
set /p "CHOICE=Select [1-9,D,Q]: "

if "%CHOICE%"=="1" goto workspace_codex_safe
if "%CHOICE%"=="2" goto workspace_codex_edit
if "%CHOICE%"=="3" goto workspace_claude_plan
if "%CHOICE%"=="4" goto workspace_claude_manual
if "%CHOICE%"=="5" goto workspace_opencode_plan
if "%CHOICE%"=="6" goto workspace_opencode_build
if "%CHOICE%"=="7" goto workspace_crush
if "%CHOICE%"=="8" goto workspace_goose
if "%CHOICE%"=="9" goto accounts
if /I "%CHOICE%"=="D" goto diagnostics
if /I "%CHOICE%"=="Q" exit /b 0
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

:workspace_opencode_plan
if not exist "%OPENCODE_EXE%" goto missing_opencode
call :choose_workspace
if errorlevel 1 goto menu
"%OPENCODE_EXE%" --agent plan
pause
goto menu

:workspace_opencode_build
if not exist "%OPENCODE_EXE%" goto missing_opencode
call :choose_workspace
if errorlevel 1 goto menu
echo.
echo BUILD mode can edit files and run commands. Review permission prompts.
pause
"%OPENCODE_EXE%" --agent build
pause
goto menu

:workspace_crush
if not exist "%CRUSH_EXE%" goto missing_crush
call :choose_workspace
if errorlevel 1 goto menu
echo.
echo Crush has direct access to mounted disks. Do not use --yolo in WinPE.
pause
"%CRUSH_EXE%"
pause
goto menu

:workspace_goose
if not exist "%GOOSE_EXE%" goto missing_goose
call :choose_workspace
if errorlevel 1 goto menu
echo.
echo Goose extensions can execute commands with direct disk access.
pause
"%GOOSE_EXE%" session
pause
goto menu

:accounts
cls
echo ================================================================
echo   Portable AI - Accounts and providers
echo ================================================================
echo.
echo   1. Codex login ^(device code^)
echo   2. Claude login
echo   3. OpenCode provider login
echo   4. Goose configure provider
echo   5. Logout Codex, Claude, and OpenCode
echo   6. Back
echo.
set "ACCOUNT_CHOICE="
set /p "ACCOUNT_CHOICE=Select [1-6]: "
if "%ACCOUNT_CHOICE%"=="1" goto codex_login
if "%ACCOUNT_CHOICE%"=="2" goto claude_login
if "%ACCOUNT_CHOICE%"=="3" goto opencode_login
if "%ACCOUNT_CHOICE%"=="4" goto goose_configure
if "%ACCOUNT_CHOICE%"=="5" goto logout
if "%ACCOUNT_CHOICE%"=="6" goto menu
goto accounts

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

:opencode_login
if not exist "%OPENCODE_EXE%" goto missing_opencode
"%OPENCODE_EXE%" auth login
pause
goto accounts

:goose_configure
if not exist "%GOOSE_EXE%" goto missing_goose
"%GOOSE_EXE%" configure
pause
goto accounts

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
if exist "%OPENCODE_EXE%" "%OPENCODE_EXE%" --version
if exist "%CRUSH_EXE%" "%CRUSH_EXE%" --version
if exist "%GOOSE_EXE%" "%GOOSE_EXE%" --version
where git.exe 2>nul
echo.
ipconfig
pause
goto menu

:logout
if exist "%CODEX_EXE%" "%CODEX_EXE%" logout
if exist "%CLAUDE_EXE%" "%CLAUDE_EXE%" auth logout
if exist "%OPENCODE_EXE%" "%OPENCODE_EXE%" auth logout
echo Selected account tokens were removed from the portable profile.
echo Crush and Goose provider keys must be removed through their own configuration.
pause
goto accounts

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

:missing_opencode
echo.
echo OpenCode binary is missing. Run Update-PortableAI.cmd on full Windows.
pause
goto menu

:missing_crush
echo.
echo Crush binary is missing. Run Update-PortableAI.cmd on full Windows.
pause
goto menu

:missing_goose
echo.
echo Goose binary is missing. Run Update-PortableAI.cmd on full Windows.
pause
goto menu
