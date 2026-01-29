@echo off
REM NPKI Agent Windows Uninstallation Script
REM This script removes NPKI Agent startup task

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
set TASK_NAME=NPKIAgent
set BINARY_NAME=fair-npki-agent.exe

REM Stop the application
echo Stopping NPKI Agent...
taskkill /F /IM %BINARY_NAME% >nul 2>&1
if %errorlevel% equ 0 (
    echo Application stopped successfully.
) else (
    echo Application was not running.
)

REM Wait for process to terminate
timeout /t 2 /nobreak >nul

REM Remove scheduled task
echo Removing startup task...
schtasks /delete /tn %TASK_NAME% /f >nul 2>&1
if %errorlevel% equ 0 (
    echo Startup task removed successfully.
) else (
    echo Startup task was not found or already removed.
)

echo.
echo ========================================
echo Uninstallation completed!
echo ========================================
echo.
echo The application will no longer start automatically on boot.
echo.
echo Note: This script only removes the startup task.
echo To completely remove the application, delete the installation folder:
echo   C:\Program Files\NPKIAgent\
echo.

pause
