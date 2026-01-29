@echo off
REM NPKI Agent Windows Service Installation Script
REM This script installs NPKI Agent as a Windows Service using NSSM

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
set SERVICE_NAME=NPKIAgent
set SERVICE_DISPLAY_NAME=NPKI Certificate Agent
set SERVICE_DESCRIPTION=NPKI Certificate Auto-Discovery Agent
set INSTALL_DIR=%~dp0
set NSSM_PATH=%INSTALL_DIR%nssm.exe
set BINARY_PATH=%INSTALL_DIR%fair-npki-agent.exe
set LOG_DIR=%PROGRAMDATA%\fair-npki-agent
set LOG_FILE=%LOG_DIR%\npki-agent.log

REM Check if NSSM exists
if not exist "%NSSM_PATH%" (
    echo ERROR: NSSM not found at %NSSM_PATH%
    echo Please make sure nssm.exe is in the same directory as this script.
    pause
    exit /b 1
)

REM Check if binary exists
if not exist "%BINARY_PATH%" (
    echo ERROR: Binary not found at %BINARY_PATH%
    echo Please make sure fair-npki-agent.exe is in the same directory as this script.
    pause
    exit /b 1
)

REM Create log directory
if not exist "%LOG_DIR%" (
    echo Creating log directory...
    mkdir "%LOG_DIR%"
)

REM Check if service already exists
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Service already exists. Stopping and removing...
    "%NSSM_PATH%" stop %SERVICE_NAME%
    timeout /t 2 /nobreak >nul
    "%NSSM_PATH%" remove %SERVICE_NAME% confirm
)

REM Install service
echo Installing Windows Service...
"%NSSM_PATH%" install %SERVICE_NAME% "%BINARY_PATH%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to install service.
    pause
    exit /b 1
)

REM Configure service
echo Configuring service...
"%NSSM_PATH%" set %SERVICE_NAME% DisplayName "%SERVICE_DISPLAY_NAME%"
"%NSSM_PATH%" set %SERVICE_NAME% Description "%SERVICE_DESCRIPTION%"
"%NSSM_PATH%" set %SERVICE_NAME% Start SERVICE_AUTO_START
"%NSSM_PATH%" set %SERVICE_NAME% AppStdout "%LOG_FILE%"
"%NSSM_PATH%" set %SERVICE_NAME% AppStderr "%LOG_FILE%"
"%NSSM_PATH%" set %SERVICE_NAME% AppRotateFiles 1
"%NSSM_PATH%" set %SERVICE_NAME% AppRotateBytes 1048576

REM Start service
echo Starting service...
"%NSSM_PATH%" start %SERVICE_NAME%
if %errorlevel% neq 0 (
    echo ERROR: Failed to start service.
    pause
    exit /b 1
)

REM Wait and verify
echo Waiting for service to start...
timeout /t 3 /nobreak >nul

REM Check if service is running
sc query %SERVICE_NAME% | find "RUNNING" >nul
if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Installation completed successfully!
    echo ========================================
    echo.
    echo Service Name: %SERVICE_NAME%
    echo Binary Location: %BINARY_PATH%
    echo Log File: %LOG_FILE%
    echo.
    echo Server is running on http://localhost:62735
    echo.
    echo To verify:
    echo   curl http://localhost:62735/npki/health
    echo.
    echo To check service:
    echo   Win + R ^> services.msc
    echo.
    echo To view logs:
    echo   type "%LOG_FILE%"
    echo.
) else (
    echo WARNING: Service installed but may not be running.
    echo Please check the service status in Services (services.msc^)
)

pause
