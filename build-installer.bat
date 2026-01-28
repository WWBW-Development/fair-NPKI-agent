@echo off
REM Build NPKI Agent Windows Installer
REM Creates fair-npki-agent-windows.exe using Inno Setup

echo Building NPKI Agent Windows Installer...
echo.

REM Check if we're on Windows
if not "%OS%"=="Windows_NT" (
    echo ERROR: This script only runs on Windows.
    exit /b 1
)

REM Step 1: Build TypeScript
echo [1/3] Compiling TypeScript...
call npm run type-check
if %errorlevel% neq 0 (
    echo ERROR: TypeScript compilation failed.
    pause
    exit /b 1
)
echo.

REM Step 2: Build Windows binary with pkg
echo [2/3] Building Windows binary...
call npm run pack:win
if %errorlevel% neq 0 (
    echo ERROR: Binary build failed.
    pause
    exit /b 1
)

REM Verify binary exists
if not exist "build\npki-agent-win.exe" (
    echo ERROR: Binary not found at build\npki-agent-win.exe
    pause
    exit /b 1
)

set BINARY_SIZE=0
for %%A in ("build\npki-agent-win.exe") do set BINARY_SIZE=%%~zA
echo Binary built: build\npki-agent-win.exe (%BINARY_SIZE% bytes^)
echo.

REM Step 3: Build installer with Inno Setup
echo [3/3] Building installer with Inno Setup...

REM Find Inno Setup compiler
set ISCC=""
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set ISCC="%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
) else if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set ISCC="%ProgramFiles%\Inno Setup 6\ISCC.exe"
) else (
    echo ERROR: Inno Setup not found.
    echo Please install Inno Setup from: https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

REM Compile installer
%ISCC% "installer\setup.iss"
if %errorlevel% neq 0 (
    echo ERROR: Installer build failed.
    pause
    exit /b 1
)
echo.

REM Verify installer exists
if not exist "build\fair-npki-agent-windows.exe" (
    echo ERROR: Installer not found at build\fair-npki-agent-windows.exe
    pause
    exit /b 1
)

REM Get installer size
set INSTALLER_SIZE=0
for %%A in ("build\fair-npki-agent-windows.exe") do set INSTALLER_SIZE=%%~zA
for /f "tokens=1,2,3 delims=/" %%a in ('echo %INSTALLER_SIZE%') do (
    set /a INSTALLER_MB=%%a/1048576
)

echo ========================================
echo Build complete!
echo ========================================
echo.
echo Installer: build\fair-npki-agent-windows.exe
echo Size: %INSTALLER_SIZE% bytes (~%INSTALLER_MB% MB^)
echo.
echo To test installation:
echo   1. Run as Administrator: build\fair-npki-agent-windows.exe
echo   2. Follow the installation wizard
echo   3. Verify: curl http://localhost:62735/npki/health
echo.
echo To uninstall:
echo   - Use "Add or Remove Programs" in Windows Settings
echo   - Or run: "%ProgramFiles%\NPKIAgent\uninstall.bat"
echo.

pause
