@echo off
echo Starting Spring Boot JAR (built with Gradle, standard JVM)...
echo.
echo API will be available at: http://localhost:5002
echo Endpoints:
echo   - http://localhost:5002/users
echo   - http://localhost:5002/benchmark
echo.

if not exist "build\libs\spring-boot-graalvm-1.0.0.jar" (
    echo ERROR: JAR file not found!
    echo Please run build-jar-gradle.bat first
    exit /b 1
)

java -jar build\libs\spring-boot-graalvm-1.0.0.jar
