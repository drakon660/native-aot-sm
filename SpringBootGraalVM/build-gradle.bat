@echo off
echo Building Spring Boot with Gradle (GraalVM Native Image)...
echo.

REM Set GraalVM environment variables
set GRAALVM_HOME=C:\graalvm
set JAVA_HOME=C:\graalvm

REM Check if Gradle is installed
where gradle >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Gradle not found!
    echo.
    echo Please install Gradle:
    echo   Option 1: Download from https://gradle.org/install/
    echo   Option 2: Use Chocolatey: choco install gradle
    echo   Option 3: Use Scoop: scoop install gradle
    echo.
    exit /b 1
)

REM Check if GraalVM is installed
where native-image >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: GraalVM native-image not found!
    echo Please install GraalVM and add it to your PATH
    echo Download from: https://www.graalvm.org/downloads/
    exit /b 1
)

echo Step 1: Clean and build with Gradle...
call gradle clean build -x test
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Gradle build failed
    exit /b 1
)

echo.
echo Step 2: Building native image with Gradle...
call gradle nativeCompile
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Native image build failed
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo Native executable location: build\native\nativeCompile\spring-boot-graalvm.exe
echo.
echo To run:
echo   build\native\nativeCompile\spring-boot-graalvm.exe
echo.
echo Or use run-gradle.bat
