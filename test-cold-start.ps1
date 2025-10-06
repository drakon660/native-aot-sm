param(
    [int]$Iterations = 5,
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

$rootPath = $PSScriptRoot
$publishPath = Join-Path $rootPath "publish"

Write-Host "=== Cold Start Performance Test ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "This test measures how quickly each API starts from scratch." -ForegroundColor Yellow
Write-Host "Iterations: $Iterations" -ForegroundColor White
Write-Host ""

# Make sure all APIs are built
$standardPath = Join-Path $publishPath "StandardMinimalApi"
$aotPath = Join-Path $publishPath "AotMinimalApi"
$javaGraalPath = Join-Path $rootPath "SpringBootGraalVM\build\native\nativeCompile"

if (-not (Test-Path $standardPath)) {
    Write-Host "StandardMinimalApi not found. Building..." -ForegroundColor Yellow
    & pwsh -File "$rootPath\build-and-run.ps1" -Project standard -Configuration $Configuration
}

if (-not (Test-Path $aotPath)) {
    Write-Host "AotMinimalApi not found. Building..." -ForegroundColor Yellow
    & pwsh -File "$rootPath\build-and-run.ps1" -Project aot -Configuration $Configuration
}

if (-not (Test-Path (Join-Path $javaGraalPath "spring-boot-graalvm.exe"))) {
    Write-Host "Java GraalVM native image not found. Please build it first with:" -ForegroundColor Yellow
    Write-Host "  cd SpringBootGraalVM && .\build-gradle.bat" -ForegroundColor White
    $javaGraalPath = $null
}

Write-Host ""

# Function to measure cold start
function Measure-ColdStart {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Executable,
        [string]$Url,
        [int]$Port
    )

    Write-Host "Testing $Name cold starts..." -ForegroundColor Cyan
    $startupTimes = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Host "  Iteration $i/$Iterations..." -ForegroundColor Gray

        # Make sure port is free
        $existing = Get-Process | Where-Object { $_.ProcessName -like "*$Executable*" }
        if ($existing) {
            Stop-Process -Name $Executable -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }

        # Kill any process using the port
        $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        if ($connection) {
            $processId = $connection.OwningProcess
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 500
        }

        # Start timing
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Start the process
        $env:ASPNETCORE_URLS = $Url
        $process = if ($Executable -like "*.exe") {
            Start-Process -FilePath (Join-Path $Path $Executable) -WorkingDirectory $Path -PassThru -WindowStyle Hidden
        } else {
            Start-Process -FilePath "dotnet" -ArgumentList (Join-Path $Path $Executable) -WorkingDirectory $Path -PassThru -WindowStyle Hidden
        }

        # Wait for the API to respond
        $maxWaitSeconds = 30
        $ready = $false

        for ($j = 0; $j -lt ($maxWaitSeconds * 10); $j++) {
            Start-Sleep -Milliseconds 100
            try {
                $response = Invoke-WebRequest -Uri "$Url/benchmark" -TimeoutSec 1 -ErrorAction SilentlyContinue
                if ($response.StatusCode -eq 200) {
                    $ready = $true
                    break
                }
            } catch { }
        }

        $stopwatch.Stop()

        if ($ready) {
            $startupTimes += $stopwatch.ElapsedMilliseconds
            Write-Host "    ✓ Started in $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed to start within $maxWaitSeconds seconds" -ForegroundColor Red
        }

        # Clean up
        try {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        } catch { }

        # Wait a bit before next iteration
        Start-Sleep -Milliseconds 1000
    }

    Write-Host ""
    return $startupTimes
}

# Test Standard API
Write-Host "=== Standard API Cold Start ===" -ForegroundColor Yellow
$standardTimes = Measure-ColdStart `
    -Name "Standard API" `
    -Path $standardPath `
    -Executable "StandardMinimalApi.dll" `
    -Url "http://localhost:5000" `
    -Port 5000

# Test AOT API
Write-Host "=== Native AOT API Cold Start ===" -ForegroundColor Yellow
$aotTimes = Measure-ColdStart `
    -Name "AOT API" `
    -Path $aotPath `
    -Executable "AotMinimalApi.exe" `
    -Url "http://localhost:5001" `
    -Port 5001

# Test Java GraalVM API
if ($javaGraalPath) {
    Write-Host "=== Java GraalVM Native Image Cold Start ===" -ForegroundColor Yellow
    $javaGraalTimes = Measure-ColdStart `
        -Name "Java GraalVM API" `
        -Path $javaGraalPath `
        -Executable "spring-boot-graalvm.exe" `
        -Url "http://localhost:5002" `
        -Port 5002
} else {
    $javaGraalTimes = @()
}

# Calculate statistics
Write-Host "=== Cold Start Results ===" -ForegroundColor Cyan
Write-Host ""

if ($standardTimes.Count -gt 0) {
    $standardAvg = ($standardTimes | Measure-Object -Average).Average
    $standardMin = ($standardTimes | Measure-Object -Minimum).Minimum
    $standardMax = ($standardTimes | Measure-Object -Maximum).Maximum

    Write-Host "Standard API:" -ForegroundColor Yellow
    Write-Host "  Average: $([math]::Round($standardAvg, 2)) ms" -ForegroundColor White
    Write-Host "  Min:     $standardMin ms" -ForegroundColor White
    Write-Host "  Max:     $standardMax ms" -ForegroundColor White
    Write-Host "  All:     $($standardTimes -join ', ') ms" -ForegroundColor Gray
    Write-Host ""
}

if ($aotTimes.Count -gt 0) {
    $aotAvg = ($aotTimes | Measure-Object -Average).Average
    $aotMin = ($aotTimes | Measure-Object -Minimum).Minimum
    $aotMax = ($aotTimes | Measure-Object -Maximum).Maximum

    Write-Host "C# Native AOT API:" -ForegroundColor Yellow
    Write-Host "  Average: $([math]::Round($aotAvg, 2)) ms" -ForegroundColor White
    Write-Host "  Min:     $aotMin ms" -ForegroundColor White
    Write-Host "  Max:     $aotMax ms" -ForegroundColor White
    Write-Host "  All:     $($aotTimes -join ', ') ms" -ForegroundColor Gray
    Write-Host ""
}

if ($javaGraalTimes.Count -gt 0) {
    $javaGraalAvg = ($javaGraalTimes | Measure-Object -Average).Average
    $javaGraalMin = ($javaGraalTimes | Measure-Object -Minimum).Minimum
    $javaGraalMax = ($javaGraalTimes | Measure-Object -Maximum).Maximum

    Write-Host "Java GraalVM Native Image:" -ForegroundColor Yellow
    Write-Host "  Average: $([math]::Round($javaGraalAvg, 2)) ms" -ForegroundColor White
    Write-Host "  Min:     $javaGraalMin ms" -ForegroundColor White
    Write-Host "  Max:     $javaGraalMax ms" -ForegroundColor White
    Write-Host "  All:     $($javaGraalTimes -join ', ') ms" -ForegroundColor Gray
    Write-Host ""
}

# Comparison
Write-Host "=== Comparison ===" -ForegroundColor Cyan
Write-Host ""

if ($standardTimes.Count -gt 0 -and $aotTimes.Count -gt 0) {
    $speedup = [math]::Round(($standardAvg / $aotAvg), 2)
    $improvement = [math]::Round((($standardAvg - $aotAvg) / $standardAvg * 100), 2)

    Write-Host "C# AOT vs C# Standard:" -ForegroundColor White
    if ($aotAvg -lt $standardAvg) {
        Write-Host "  AOT is ${speedup}x faster" -ForegroundColor Green
        Write-Host "  Cold start improvement: ${improvement}%" -ForegroundColor Green
        Write-Host "  Time saved: $([math]::Round($standardAvg - $aotAvg, 2)) ms" -ForegroundColor Green
    } else {
        Write-Host "  Standard is $([math]::Round($aotAvg / $standardAvg, 2))x faster" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($standardTimes.Count -gt 0 -and $javaGraalTimes.Count -gt 0) {
    $speedup = [math]::Round(($standardAvg / $javaGraalAvg), 2)
    $improvement = [math]::Round((($standardAvg - $javaGraalAvg) / $standardAvg * 100), 2)

    Write-Host "Java GraalVM vs C# Standard:" -ForegroundColor White
    if ($javaGraalAvg -lt $standardAvg) {
        Write-Host "  Java GraalVM is ${speedup}x faster" -ForegroundColor Green
        Write-Host "  Cold start improvement: ${improvement}%" -ForegroundColor Green
        Write-Host "  Time saved: $([math]::Round($standardAvg - $javaGraalAvg, 2)) ms" -ForegroundColor Green
    } else {
        Write-Host "  Standard is $([math]::Round($javaGraalAvg / $standardAvg, 2))x faster" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($aotTimes.Count -gt 0 -and $javaGraalTimes.Count -gt 0) {
    $speedup = [math]::Round(($aotAvg / $javaGraalAvg), 2)
    $improvement = [math]::Round((($aotAvg - $javaGraalAvg) / $aotAvg * 100), 2)

    Write-Host "Java GraalVM vs C# AOT:" -ForegroundColor White
    if ($javaGraalAvg -lt $aotAvg) {
        Write-Host "  Java GraalVM is ${speedup}x faster" -ForegroundColor Green
        Write-Host "  Cold start improvement: ${improvement}%" -ForegroundColor Green
        Write-Host "  Time saved: $([math]::Round($aotAvg - $javaGraalAvg, 2)) ms" -ForegroundColor Green
    } else {
        Write-Host "  C# AOT is $([math]::Round($javaGraalAvg / $aotAvg, 2))x faster" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Chart
Write-Host "Visual Comparison:" -ForegroundColor White
$allAvgs = @()
if ($standardTimes.Count -gt 0) { $allAvgs += $standardAvg }
if ($aotTimes.Count -gt 0) { $allAvgs += $aotAvg }
if ($javaGraalTimes.Count -gt 0) { $allAvgs += $javaGraalAvg }

if ($allAvgs.Count -gt 0) {
    $maxTime = ($allAvgs | Measure-Object -Maximum).Maximum

    if ($standardTimes.Count -gt 0) {
        $standardBar = "█" * [math]::Floor(($standardAvg / $maxTime) * 50)
        Write-Host "  C# Standard:    $standardBar $([math]::Round($standardAvg, 0)) ms" -ForegroundColor Cyan
    }

    if ($aotTimes.Count -gt 0) {
        $aotBar = "█" * [math]::Floor(($aotAvg / $maxTime) * 50)
        Write-Host "  C# AOT:         $aotBar $([math]::Round($aotAvg, 0)) ms" -ForegroundColor Green
    }

    if ($javaGraalTimes.Count -gt 0) {
        $javaGraalBar = "█" * [math]::Floor(($javaGraalAvg / $maxTime) * 50)
        Write-Host "  Java GraalVM:   $javaGraalBar $([math]::Round($javaGraalAvg, 0)) ms" -ForegroundColor Magenta
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
