@echo off
echo Starting Spring Boot GraalVM Native (built with Gradle)...
echo.
echo API will be available at: http://localhost:5002
echo Endpoints:
echo   - http://localhost:5002/users
echo   - http://localhost:5002/benchmark
echo.

if not exist "build\native\nativeCompile\spring-boot-graalvm.exe" (
    echo ERROR: Native executable not found!
    echo Please run build-gradle.bat first
    exit /b 1
)

build\native\nativeCompile\spring-boot-graalvm.exe
