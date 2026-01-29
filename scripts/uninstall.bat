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
set INSTALL_DIR=%~dp0
set NSSM_PATH=%INSTALL_DIR%nssm.exe

REM Check if NSSM exists
if not exist "%NSSM_PATH%" (
    echo ERROR: NSSM not found at %NSSM_PATH%
    echo Trying to use system NSSM...
    where nssm >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: NSSM not found in system PATH either.
        echo Please manually remove the service using:
        echo   sc delete %SERVICE_NAME%
        pause
        exit /b 1
    )
    set NSSM_PATH=nssm
)

REM Check if service exists
sc query %SERVICE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo Service does not exist or is already removed.
    echo.
    pause
    exit /b 0
)

REM Stop the service
echo Stopping Windows Service...
"%NSSM_PATH%" stop %SERVICE_NAME%
if %errorlevel% equ 0 (
    echo Service stopped successfully.
) else (
    echo Service was not running or failed to stop.
)

REM Wait for service to stop
timeout /t 2 /nobreak >nul

REM Remove the service
echo Removing Windows Service...
"%NSSM_PATH%" remove %SERVICE_NAME% confirm
if %errorlevel% equ 0 (
    echo Service removed successfully.
) else (
    echo Failed to remove service.
    echo Trying alternative method...
    sc delete %SERVICE_NAME%
    if %errorlevel% equ 0 (
        echo Service removed successfully using sc.exe
    ) else (
        echo Failed to remove service with sc.exe as well.
    )
)

echo.
echo ========================================
echo Uninstallation completed!
echo ========================================
echo.
echo The Windows Service has been removed.
echo The application will no longer start automatically on boot.
echo.
echo Note: This script only removes the service.
echo To completely remove the application, delete the installation folder:
echo   C:\Program Files\NPKIAgent\
echo.
echo To remove log files:
echo   %PROGRAMDATA%\fair-npki-agent\
echo.

pause
