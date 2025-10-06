# Native AOT Optimizations Applied

## Project Configuration (AotMinimalApi.csproj)

### Core AOT Settings
- **`PublishAot=true`**: Enables Native AOT compilation
- **`InvariantGlobalization=true`**: Disables globalization features for smaller size and faster startup
- **`SelfContained=true`**: Creates self-contained executable without .NET runtime dependency

### Performance Optimizations
- **`OptimizationPreference=Speed`**: Optimizes for execution speed
- **`IlcOptimizationPreference=Speed`**: ILC (IL Compiler) optimizes for speed over size
- **`IlcGenerateStackTraceData=false`**: Removes stack trace generation for better performance
- **`TieredCompilation=true`**: Enables tiered compilation
- **`TieredCompilationQuickJit=false`**: Disables quick JIT for AOT

### Size Optimizations
- **`PublishTrimmed=true`**: Removes unused code
- **`TrimMode=full`**: Aggressive trimming of unused assemblies
- **`DebugType=none`**: Removes debug symbols
- **`DebugSymbols=false`**: No debug symbols in release

## Code Optimizations (Program.cs)

### Removed Services
- **Authorization**: Removed `AddAuthorization()` and `UseAuthorization()` - not needed for this demo
- **OpenAPI**: Only added in Development mode to reduce production overhead

### Kept Optimizations
- **`CreateSlimBuilder`**: Uses minimal ASP.NET Core services
- **Source-generated JSON**: Uses `AppJsonSerializerContext` for AOT-compatible JSON serialization
- **Minimal middleware**: Only essential middleware in the pipeline

## Expected Performance Benefits

### Startup Time
- **Standard .NET**: ~500-1500ms cold start
- **Native AOT**: ~50-300ms cold start
- **Improvement**: 5-10x faster startup

### Memory Usage
- **Standard .NET**: ~50-80 MB working set
- **Native AOT**: ~15-30 MB working set
- **Improvement**: 50-60% less memory

### Deployment Size
- **Standard .NET**: ~90-120 MB (with runtime)
- **Native AOT**: ~10-20 MB (self-contained)
- **Improvement**: 80-90% smaller

### Runtime Performance
- **Similar performance** for CPU-intensive tasks (benchmark endpoint)
- **Slightly better** for I/O and network operations
- **No JIT warmup** needed - full speed from first request

## Trade-offs

### Advantages
✓ Much faster startup time (5-10x)
✓ Lower memory footprint (50-60% reduction)
✓ Smaller deployment size (80-90% reduction)
✓ No .NET runtime required
✓ Better for serverless/container scenarios
✓ Predictable performance (no JIT)

### Limitations
✗ Longer build time (native compilation is slow)
✗ No dynamic code generation (Reflection.Emit)
✗ Limited reflection support
✗ Some libraries not compatible
✗ Larger executable than framework-dependent deployment

## Testing Performance

### Measure Startup Time
```powershell
.\build-and-run.ps1
# Choose option 3 to run both APIs
# Compare the startup times displayed
```

### Measure Runtime Performance
```powershell
.\test-performance.ps1
# Compares execution time and memory usage between both APIs
```

### Check Deployment Size
```powershell
# Standard API
Get-ChildItem publish\StandardMinimalApi -Recurse | Measure-Object -Property Length -Sum

# AOT API
Get-ChildItem publish\AotMinimalApi -Recurse | Measure-Object -Property Length -Sum
```

## Environment-Specific Settings

### Production (ASPNETCORE_ENVIRONMENT=Production)
- OpenAPI disabled
- Authorization removed
- Minimal services loaded
- Maximum performance

### Development (ASPNETCORE_ENVIRONMENT=Development)
- OpenAPI enabled for testing
- Swagger UI available
- Easier debugging

## Further Optimizations (Optional)

If you want even smaller size, uncomment in .csproj:
```xml
<IlcOptimizationPreference>Size</IlcOptimizationPreference>
```

For even more aggressive trimming, add:
```xml
<IlcTrimMetadata>true</IlcTrimMetadata>
<IlcFoldIdenticalMethodBodies>true</IlcFoldIdenticalMethodBodies>
```

**Note**: These may impact debugging and error messages.
