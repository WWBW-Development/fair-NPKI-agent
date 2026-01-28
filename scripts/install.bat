@echo off
REM NPKI Agent Windows Service Installation Script
REM This script installs NPKI Agent as a Windows Service

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
set INSTALL_DIR=%ProgramFiles%\NPKIAgent
set BINARY_NAME=fair-npki-agent.exe
set LOG_FILE=%TEMP%\fair-npki-agent.log

REM Create installation directory
if not exist "%INSTALL_DIR%" (
    echo Creating installation directory...
    mkdir "%INSTALL_DIR%"
)

REM Copy binary
echo Copying binary to %INSTALL_DIR%...
copy /Y "%~dp0..\build\npki-agent-win.exe" "%INSTALL_DIR%\%BINARY_NAME%" >nul
if %errorlevel% neq 0 (
    echo ERROR: Failed to copy binary.
    pause
    exit /b 1
)

REM Check if NSSM is available
where nssm >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: NSSM (Non-Sucking Service Manager) is not installed.
    echo Please install NSSM from https://nssm.cc/download
    echo Or use Chocolatey: choco install nssm
    pause
    exit /b 1
)

REM Check if service already exists
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Service already exists. Stopping and removing...
    nssm stop %SERVICE_NAME%
    timeout /t 2 /nobreak >nul
    nssm remove %SERVICE_NAME% confirm
)

REM Install service
echo Installing Windows Service...
nssm install %SERVICE_NAME% "%INSTALL_DIR%\%BINARY_NAME%"
if %errorlevel% neq 0 (
    echo ERROR: Failed to install service.
    pause
    exit /b 1
)

REM Configure service
echo Configuring service...
nssm set %SERVICE_NAME% DisplayName "%SERVICE_DISPLAY_NAME%"
nssm set %SERVICE_NAME% Description "%SERVICE_DESCRIPTION%"
nssm set %SERVICE_NAME% Start SERVICE_AUTO_START
nssm set %SERVICE_NAME% AppStdout "%LOG_FILE%"
nssm set %SERVICE_NAME% AppStderr "%LOG_FILE%"
nssm set %SERVICE_NAME% AppRotateFiles 1
nssm set %SERVICE_NAME% AppRotateBytes 1048576

REM Start service
echo Starting service...
nssm start %SERVICE_NAME%
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
    echo Install Location: %INSTALL_DIR%
    echo Log File: %LOG_FILE%
    echo.
    echo Server is running on http://localhost:62735
    echo.
    echo To verify:
    echo   curl http://localhost:62735/npki/health
    echo.
    echo To check logs:
    echo   type "%LOG_FILE%"
    echo.
) else (
    echo WARNING: Service installed but may not be running.
    echo Please check the service status in Services (services.msc^)
)

pause
