@echo off
REM NPKI Agent Windows Service Uninstallation Script
REM This script removes NPKI Agent Windows Service

echo Uninstalling NPKI Agent...

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
set INSTALL_DIR=%ProgramFiles%\NPKIAgent
set LOG_FILE=%TEMP%\fair-npki-agent.log

REM Check if NSSM is available
where nssm >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: NSSM is not installed. Trying to remove service with sc...
    sc query %SERVICE_NAME% >nul 2>&1
    if %errorlevel% equ 0 (
        sc stop %SERVICE_NAME%
        timeout /t 2 /nobreak >nul
        sc delete %SERVICE_NAME%
    )
    goto cleanup
)

REM Check if service exists
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo Service is not installed.
    goto cleanup
)

REM Stop service
echo Stopping service...
nssm stop %SERVICE_NAME%
timeout /t 2 /nobreak >nul

REM Remove service
echo Removing service...
nssm remove %SERVICE_NAME% confirm
if %errorlevel% neq 0 (
    echo WARNING: Failed to remove service with NSSM. Trying sc...
    sc delete %SERVICE_NAME%
)

:cleanup
REM Remove installation directory
if exist "%INSTALL_DIR%" (
    echo Removing installation directory...
    timeout /t 1 /nobreak >nul
    rmdir /S /Q "%INSTALL_DIR%" 2>nul
    if exist "%INSTALL_DIR%" (
        echo WARNING: Could not remove %INSTALL_DIR%
        echo Please remove it manually.
    ) else (
        echo Installation directory removed.
    )
)

REM Remove log file
if exist "%LOG_FILE%" (
    echo Removing log file...
    del /F /Q "%LOG_FILE%" 2>nul
)

REM Verify removal
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo Uninstallation completed successfully!
    echo ========================================
    echo.
) else (
    echo.
    echo WARNING: Service may still exist.
    echo Please check Services (services.msc^) and remove manually.
    echo.
)

pause
