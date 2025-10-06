@echo off
echo Building Spring Boot JAR with Gradle (standard, non-native)...
echo.

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

call gradle clean bootJar -x test
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Gradle build failed
    exit /b 1
)

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo JAR location: build\libs\spring-boot-graalvm-1.0.0.jar
echo.
echo To run:
echo   java -jar build\libs\spring-boot-graalvm-1.0.0.jar
echo.
echo Or use run-jar-gradle.bat
