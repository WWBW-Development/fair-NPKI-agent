@echo off
REM NPKI Agent Windows Installation Script
REM This script registers NPKI Agent to start automatically on boot

echo Installing NPKI Agent...

REM Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please run as Administrator.
    pause
    exit /b 1
)

REM Set variables
set TASK_NAME=NPKIAgent
set INSTALL_DIR=%~dp0
set BINARY_NAME=fair-npki-agent.exe
set BINARY_PATH=%INSTALL_DIR%%BINARY_NAME%

REM Check if binary exists
if not exist "%BINARY_PATH%" (
    echo ERROR: Binary not found at %BINARY_PATH%
    echo Please make sure %BINARY_NAME% is in the same directory as this script.
    pause
    exit /b 1
)

REM Check if task already exists
schtasks /query /tn %TASK_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Task already exists. Removing existing task...
    schtasks /delete /tn %TASK_NAME% /f
)

REM Stop existing process
echo Stopping existing process if running...
taskkill /F /IM %BINARY_NAME% >nul 2>&1

REM Create scheduled task
echo Creating startup task...
schtasks /create /tn %TASK_NAME% /tr "\"%BINARY_PATH%\"" /sc onstart /ru SYSTEM /rl highest /f
if %errorlevel% neq 0 (
    echo ERROR: Failed to create startup task.
    pause
    exit /b 1
)

REM Start the application immediately
echo Starting NPKI Agent...
start "" "%BINARY_PATH%"

REM Wait for startup
timeout /t 3 /nobreak >nul

echo.
echo ========================================
echo Installation completed successfully!
echo ========================================
echo.
echo Task Name: %TASK_NAME%
echo Binary Location: %BINARY_PATH%
echo.
echo The application will start automatically on system boot.
echo Server will be available on http://localhost:62735
echo.
echo To verify:
echo   curl http://localhost:62735/npki/health
echo.
echo To check task status:
echo   schtasks /query /tn %TASK_NAME%
echo.
echo To view all tasks:
echo   Win + R ^> taskschd.msc
echo.

pause
