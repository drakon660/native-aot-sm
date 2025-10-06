# Spring Boot with GraalVM Native Image

This is a Spring Boot application equivalent to the .NET APIs in this solution, created for performance comparison.

## Prerequisites

- **Java 21+** (JDK)
- **Gradle** - Install using one of these methods:
  - Download from: https://gradle.org/install/
  - Chocolatey: `choco install gradle`
  - Scoop: `scoop install gradle`
- **GraalVM** (for native image compilation)
  - Download from: https://www.graalvm.org/downloads/
  - Install native-image: `gu install native-image`

## Endpoints

- `GET /users` - Returns 10,000 generated users (JSON serialization heavy)
- `GET /benchmark` - CPU-intensive prime number calculation

## Building

**Standard JAR (JVM)**
```bash
build-jar-gradle.bat
# or
gradlew bootJar
```

**Native Image (GraalVM AOT)**
```bash
build-gradle.bat
# or
gradlew nativeCompile
```

## Running

**Standard JAR**
```bash
run-jar-gradle.bat
# or
java -jar build/libs/spring-boot-graalvm-1.0.0.jar
```

**Native Image**
```bash
run-gradle.bat
# or
build/native/nativeCompile/spring-boot-graalvm.exe
```

## Testing

The API runs on port **5002** by default.

Test endpoints:
- http://localhost:5002/users
- http://localhost:5002/benchmark

## Performance Comparison

To compare with .NET APIs, run the compare-performance.ps1 script from the root directory after starting all APIs:

```powershell
# Start all APIs
.\build-and-run.ps1 -RunOnly  # .NET APIs on ports 5000, 5001
.\SpringBootGraalVM\run.bat   # Spring Boot on port 5002

# Run comparison
.\compare-performance.ps1
```

## Configuration

- Port: 5002 (configured in `application.properties`)
- Server: Undertow (for better performance than Tomcat)
- JMX: Disabled
- Banner: Disabled

## Native Image Build Time

Native image compilation can take several minutes depending on your system. This is normal for GraalVM Native Image.
