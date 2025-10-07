@echo off
setlocal

set PUBLISH_PATH=%~dp0publish

echo.
echo === Starting APIs ===
echo.

REM Check if publish directory exists
if not exist "%PUBLISH_PATH%" (
    echo Error: Publish directory not found
    echo Please run build-and-run.ps1 first to build the projects
    pause
    exit /b 1
)

REM Copy startup scripts to publish directory
echo Copying startup scripts...
copy /Y "%~dp0start-standard.bat" "%PUBLISH_PATH%\start-standard.bat" >nul
copy /Y "%~dp0start-aot.bat" "%PUBLISH_PATH%\start-aot.bat" >nul

REM Start StandardMinimalApi
if exist "%PUBLISH_PATH%\start-standard.bat" (
    echo Starting StandardMinimalApi on http://localhost:5000
    start "StandardMinimalApi" /MIN cmd /c "%PUBLISH_PATH%\start-standard.bat"
    timeout /t 2 /nobreak >nul
) else (
    echo Warning: start-standard.bat not found
)

REM Start AotMinimalApi
if exist "%PUBLISH_PATH%\start-aot.bat" (
    echo Starting AotMinimalApi on http://localhost:5001
    start "AotMinimalApi" /MIN cmd /c "%PUBLISH_PATH%\start-aot.bat"
    timeout /t 2 /nobreak >nul
) else (
    echo Warning: start-aot.bat not found
)

echo.
echo === APIs Started ===
echo.
echo StandardMinimalApi: http://localhost:5000
echo AotMinimalApi:      http://localhost:5001
echo.
echo Press any key to exit (APIs will continue running in separate windows)
pause >nul
