@echo off
cd /d "%~dp0AotMinimalApi"
set ASPNETCORE_URLS=http://localhost:5001
AotMinimalApi.exe
