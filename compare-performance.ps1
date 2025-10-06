param(
    [string]$StandardUrl = "http://localhost:5000",
    [string]$AotUrl = "http://localhost:5001",
    [string]$JavaGraalUrl = "http://localhost:5002",
    [string]$RustUrl = "http://localhost:5003",
    [int]$WarmupRequests = 5,
    [int]$TestRequests = 20
)

Write-Host "=== Comprehensive Performance Comparison: Standard vs Native AOT vs Java GraalVM vs Rust ===" -ForegroundColor Cyan
Write-Host ""

# Check if APIs are running
Write-Host "Checking API availability..." -ForegroundColor Yellow
$standardAvailable = $false
$aotAvailable = $false
$javaGraalAvailable = $false
$rustAvailable = $false

try {
    $response = Invoke-WebRequest -Uri "$StandardUrl/users" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        $standardAvailable = $true
        Write-Host "  [OK] Standard API: Running at $StandardUrl" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] Standard API: Not running at $StandardUrl" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
}

try {
    $response = Invoke-WebRequest -Uri "$AotUrl/users" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        $aotAvailable = $true
        Write-Host "  [OK] AOT API: Running at $AotUrl" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] AOT API: Not running at $AotUrl" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
}

try {
    $response = Invoke-WebRequest -Uri "$JavaGraalUrl/users" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        $javaGraalAvailable = $true
        Write-Host "  [OK] Java GraalVM API: Running at $JavaGraalUrl" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] Java GraalVM API: Not running at $JavaGraalUrl" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
}

try {
    $response = Invoke-WebRequest -Uri "$RustUrl/users" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        $rustAvailable = $true
        Write-Host "  [OK] Rust API: Running at $RustUrl" -ForegroundColor Green
    }
} catch {
    Write-Host "  [ERROR] Rust API: Not running at $RustUrl" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Gray
}

if (-not $standardAvailable -and -not $aotAvailable -and -not $javaGraalAvailable -and -not $rustAvailable) {
    Write-Host "`nError: No APIs are running. Please start them first." -ForegroundColor Red
    Write-Host "`nTip: Run the APIs using:" -ForegroundColor Yellow
    Write-Host "  .\build-and-run.ps1 -RunOnly" -ForegroundColor White
    Write-Host "or build and run them with:" -ForegroundColor Yellow
    Write-Host "  .\build-and-run.ps1" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Warmup requests: $WarmupRequests"
Write-Host "  Test requests: $TestRequests"
Write-Host ""

# Warmup
Write-Host "Warming up applications..." -ForegroundColor Yellow
for ($i = 1; $i -le $WarmupRequests; $i++) {
    try {
        Write-Host "  Warm: $i"
        if ($standardAvailable) {

            Invoke-RestMethod -Uri "$StandardUrl/benchmark" -ErrorAction SilentlyContinue | Out-Null
            Invoke-RestMethod -Uri "$StandardUrl/users" -ErrorAction SilentlyContinue | Out-Null
        }
        if ($aotAvailable) {
            Invoke-RestMethod -Uri "$AotUrl/benchmark" -ErrorAction SilentlyContinue | Out-Null
            Invoke-RestMethod -Uri "$AotUrl/users" -ErrorAction SilentlyContinue | Out-Null
        }
        if ($javaGraalAvailable) {
            Invoke-RestMethod -Uri "$JavaGraalUrl/benchmark" -ErrorAction SilentlyContinue | Out-Null
            Invoke-RestMethod -Uri "$JavaGraalUrl/users" -ErrorAction SilentlyContinue | Out-Null
        }
        if ($rustAvailable) {
            Invoke-RestMethod -Uri "$RustUrl/benchmark" -ErrorAction SilentlyContinue | Out-Null
            Invoke-RestMethod -Uri "$RustUrl/users" -ErrorAction SilentlyContinue | Out-Null
        }
    } catch {}
}
Start-Sleep -Seconds 1

# Test 1: Users endpoint response time (JSON serialization heavy)
Write-Host "`n=== Test 1: Users Endpoint (/users - 10k users) ===" -ForegroundColor Cyan
Write-Host ""

if ($standardAvailable) {
    Write-Host "Testing Standard API..." -ForegroundColor Green
    $standardUsersTimes = @()
    $standardUsersSize = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$StandardUrl/users"
            $sw.Stop()
            $standardUsersTimes += $sw.ElapsedMilliseconds
            if ($i -eq 1) {
                $json = $response | ConvertTo-Json -Depth 10
                $standardUsersSize = [System.Text.Encoding]::UTF8.GetByteCount($json)
            }
        } catch {
            Write-Host "  Request $i failed" -ForegroundColor Red
        }
    }
}

if ($aotAvailable) {
    Write-Host "Testing AOT API..." -ForegroundColor Green
    $aotUsersTimes = @()
    $aotUsersSize = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$AotUrl/users"
            $sw.Stop()
            $aotUsersTimes += $sw.ElapsedMilliseconds
            if ($i -eq 1) {
                $json = $response | ConvertTo-Json -Depth 10
                $aotUsersSize = [System.Text.Encoding]::UTF8.GetByteCount($json)
            }
        } catch {
            Write-Host "  Request $i failed" -ForegroundColor Red
        }
    }
}

if ($javaGraalAvailable) {
    Write-Host "Testing Java GraalVM API..." -ForegroundColor Green
    $javaGraalUsersTimes = @()
    $javaGraalUsersSize = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$JavaGraalUrl/users"
            $sw.Stop()
            $javaGraalUsersTimes += $sw.ElapsedMilliseconds
            if ($i -eq 1) {
                $json = $response | ConvertTo-Json -Depth 10
                $javaGraalUsersSize = [System.Text.Encoding]::UTF8.GetByteCount($json)
            }
        } catch {
            Write-Host "  Request $i failed" -ForegroundColor Red
        }
    }
}

if ($rustAvailable) {
    Write-Host "Testing Rust API..." -ForegroundColor Green
    $rustUsersTimes = @()
    $rustUsersSize = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$RustUrl/users"
            $sw.Stop()
            $rustUsersTimes += $sw.ElapsedMilliseconds
            if ($i -eq 1) {
                $json = $response | ConvertTo-Json -Depth 10
                $rustUsersSize = [System.Text.Encoding]::UTF8.GetByteCount($json)
            }
        } catch {
            Write-Host "  Request $i failed" -ForegroundColor Red
        }
    }
}

# Test 2: CPU-intensive benchmark
Write-Host "`n=== Test 2: CPU-Intensive Benchmark (/benchmark - Prime calculation) ===" -ForegroundColor Cyan
Write-Host ""

if ($standardAvailable) {
    Write-Host "Testing Standard API..." -ForegroundColor Green
    $standardBenchmarkTimes = @()
    $standardMemory = 0
    $standardPrimes = 0
    $standardPid = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$StandardUrl/benchmark"
            $standardBenchmarkTimes += $result.executionTimeMs
            $standardPid = $result.processId
            $standardPrimes = $result.primesFound
            Write-Host "  Request $i : $($result.executionTimeMs) ms" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
    }
    # Get actual process memory from PID
    if ($standardPid -gt 0) {
        $process = Get-Process -Id $standardPid -ErrorAction SilentlyContinue
        if ($process) {
            $standardMemory = $process.WorkingSet64 / 1MB
        }
    }
}

if ($aotAvailable) {
    Write-Host "`nTesting AOT API..." -ForegroundColor Green
    $aotBenchmarkTimes = @()
    $aotMemory = 0
    $aotPrimes = 0
    $aotPid = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$AotUrl/benchmark"
            $aotBenchmarkTimes += $result.executionTimeMs
            $aotPid = $result.processId
            $aotPrimes = $result.primesFound
            Write-Host "  Request $i : $($result.executionTimeMs) ms" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
    }
    # Get actual process memory from PID
    if ($aotPid -gt 0) {
        $process = Get-Process -Id $aotPid -ErrorAction SilentlyContinue
        if ($process) {
            $aotMemory = $process.WorkingSet64 / 1MB
        }
    }
}

if ($javaGraalAvailable) {
    Write-Host "`nTesting Java GraalVM API..." -ForegroundColor Green
    $javaGraalBenchmarkTimes = @()
    $javaGraalMemory = 0
    $javaGraalPrimes = 0
    $javaGraalPid = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$JavaGraalUrl/benchmark"
            $javaGraalBenchmarkTimes += $result.executionTimeMs
            $javaGraalPid = $result.processId
            $javaGraalPrimes = $result.primesFound
            Write-Host "  Request $i : $($result.executionTimeMs) ms" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
    }
    # Get actual process memory from PID
    if ($javaGraalPid -gt 0) {
        $process = Get-Process -Id $javaGraalPid -ErrorAction SilentlyContinue
        if ($process) {
            $javaGraalMemory = $process.WorkingSet64 / 1MB
        }
    }
}

if ($rustAvailable) {
    Write-Host "`nTesting Rust API..." -ForegroundColor Green
    $rustBenchmarkTimes = @()
    $rustMemory = 0
    $rustPrimes = 0
    $rustPid = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$RustUrl/benchmark"
            $rustBenchmarkTimes += $result.executionTimeMs
            $rustPid = $result.processId
            $rustPrimes = $result.primesFound
            Write-Host "  Request $i : $($result.executionTimeMs) ms" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
    }
    # Get actual process memory from PID
    if ($rustPid -gt 0) {
        $process = Get-Process -Id $rustPid -ErrorAction SilentlyContinue
        if ($process) {
            $rustMemory = $process.WorkingSet64 / 1MB
        }
    }
}

# Calculate statistics
Write-Host "`n=== Results Summary ===" -ForegroundColor Cyan
Write-Host ""

# Users endpoint statistics
Write-Host "Users Endpoint (/users - 10k users, JSON serialization):" -ForegroundColor Yellow

if ($standardAvailable) {
    $standardUsersAvg = ($standardUsersTimes | Measure-Object -Average).Average
    Write-Host "  Standard API:" -ForegroundColor White
    Write-Host "    Response time: $([math]::Round($standardUsersAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Response size: $([math]::Round($standardUsersSize / 1024 / 1024, 2)) MB" -ForegroundColor Gray
}

if ($aotAvailable) {
    $aotUsersAvg = ($aotUsersTimes | Measure-Object -Average).Average
    Write-Host "  AOT API:" -ForegroundColor White
    Write-Host "    Response time: $([math]::Round($aotUsersAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Response size: $([math]::Round($aotUsersSize / 1024 / 1024, 2)) MB" -ForegroundColor Gray
}

if ($javaGraalAvailable) {
    $javaGraalUsersAvg = ($javaGraalUsersTimes | Measure-Object -Average).Average
    Write-Host "  Java GraalVM API:" -ForegroundColor White
    Write-Host "    Response time: $([math]::Round($javaGraalUsersAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Response size: $([math]::Round($javaGraalUsersSize / 1024 / 1024, 2)) MB" -ForegroundColor Gray
}

if ($rustAvailable) {
    $rustUsersAvg = ($rustUsersTimes | Measure-Object -Average).Average
    Write-Host "  Rust API:" -ForegroundColor White
    Write-Host "    Response time: $([math]::Round($rustUsersAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Response size: $([math]::Round($rustUsersSize / 1024 / 1024, 2)) MB" -ForegroundColor Gray
}

if ($standardAvailable -and $aotAvailable) {
    Write-Host "  Performance (C# AOT vs Standard):" -ForegroundColor White
    if ($aotUsersAvg -lt $standardUsersAvg) {
        $improvement = [math]::Round((($standardUsersAvg - $aotUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "    AOT is ${improvement}% faster" -ForegroundColor Green
    } elseif ($aotUsersAvg -gt $standardUsersAvg) {
        $degradation = [math]::Round((($aotUsersAvg - $standardUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "    AOT is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Same speed" -ForegroundColor White
    }
}

if ($standardAvailable -and $javaGraalAvailable) {
    Write-Host "  Performance (Java GraalVM vs C# Standard):" -ForegroundColor White
    if ($javaGraalUsersAvg -lt $standardUsersAvg) {
        $improvement = [math]::Round((($standardUsersAvg - $javaGraalUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "    Java GraalVM is ${improvement}% faster" -ForegroundColor Green
    } elseif ($javaGraalUsersAvg -gt $standardUsersAvg) {
        $degradation = [math]::Round((($javaGraalUsersAvg - $standardUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "    Java GraalVM is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Same speed" -ForegroundColor White
    }
}

if ($aotAvailable -and $javaGraalAvailable) {
    Write-Host "  Performance (Java GraalVM vs C# AOT):" -ForegroundColor White
    if ($javaGraalUsersAvg -lt $aotUsersAvg) {
        $improvement = [math]::Round((($aotUsersAvg - $javaGraalUsersAvg) / $aotUsersAvg * 100), 2)
        Write-Host "    Java GraalVM is ${improvement}% faster" -ForegroundColor Green
    } elseif ($javaGraalUsersAvg -gt $aotUsersAvg) {
        $degradation = [math]::Round((($javaGraalUsersAvg - $aotUsersAvg) / $aotUsersAvg * 100), 2)
        Write-Host "    Java GraalVM is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Same speed" -ForegroundColor White
    }
}

if ($rustAvailable -and $standardAvailable) {
    Write-Host "  Performance (Rust vs C# Standard):" -ForegroundColor White
    if ($rustUsersAvg -lt $standardUsersAvg) {
        $improvement = [math]::Round((($standardUsersAvg - $rustUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "    Rust is ${improvement}% faster" -ForegroundColor Green
    } elseif ($rustUsersAvg -gt $standardUsersAvg) {
        $degradation = [math]::Round((($rustUsersAvg - $standardUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "    Rust is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Same speed" -ForegroundColor White
    }
}

if ($rustAvailable -and $aotAvailable) {
    Write-Host "  Performance (Rust vs C# AOT):" -ForegroundColor White
    if ($rustUsersAvg -lt $aotUsersAvg) {
        $improvement = [math]::Round((($aotUsersAvg - $rustUsersAvg) / $aotUsersAvg * 100), 2)
        Write-Host "    Rust is ${improvement}% faster" -ForegroundColor Green
    } elseif ($rustUsersAvg -gt $aotUsersAvg) {
        $degradation = [math]::Round((($rustUsersAvg - $aotUsersAvg) / $aotUsersAvg * 100), 2)
        Write-Host "    Rust is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Same speed" -ForegroundColor White
    }
}

if ($rustAvailable -and $javaGraalAvailable) {
    Write-Host "  Performance (Rust vs Java GraalVM):" -ForegroundColor White
    if ($rustUsersAvg -lt $javaGraalUsersAvg) {
        $improvement = [math]::Round((($javaGraalUsersAvg - $rustUsersAvg) / $javaGraalUsersAvg * 100), 2)
        Write-Host "    Rust is ${improvement}% faster" -ForegroundColor Green
    } elseif ($rustUsersAvg -gt $javaGraalUsersAvg) {
        $degradation = [math]::Round((($rustUsersAvg - $javaGraalUsersAvg) / $javaGraalUsersAvg * 100), 2)
        Write-Host "    Rust is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Same speed" -ForegroundColor White
    }
}
Write-Host ""

# Benchmark statistics
Write-Host "CPU-Intensive Benchmark (/benchmark):" -ForegroundColor Yellow

if ($standardAvailable) {
    $standardBenchAvg = ($standardBenchmarkTimes | Measure-Object -Average).Average
    Write-Host "  Standard API:" -ForegroundColor White
    Write-Host "    Execution time: $([math]::Round($standardBenchAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Memory usage:   $([math]::Round($standardMemory, 2)) MB" -ForegroundColor Gray
    Write-Host "    Primes found:   $standardPrimes" -ForegroundColor Gray
}

if ($aotAvailable) {
    $aotBenchAvg = ($aotBenchmarkTimes | Measure-Object -Average).Average
    Write-Host "  AOT API:" -ForegroundColor White
    Write-Host "    Execution time: $([math]::Round($aotBenchAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Memory usage:   $([math]::Round($aotMemory, 2)) MB" -ForegroundColor Gray
    Write-Host "    Primes found:   $aotPrimes" -ForegroundColor Gray
}

if ($javaGraalAvailable) {
    $javaGraalBenchAvg = ($javaGraalBenchmarkTimes | Measure-Object -Average).Average
    Write-Host "  Java GraalVM API:" -ForegroundColor White
    Write-Host "    Execution time: $([math]::Round($javaGraalBenchAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Memory usage:   $([math]::Round($javaGraalMemory, 2)) MB" -ForegroundColor Gray
    Write-Host "    Primes found:   $javaGraalPrimes" -ForegroundColor Gray
}

if ($rustAvailable) {
    $rustBenchAvg = ($rustBenchmarkTimes | Measure-Object -Average).Average
    Write-Host "  Rust API:" -ForegroundColor White
    Write-Host "    Execution time: $([math]::Round($rustBenchAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Memory usage:   $([math]::Round($rustMemory, 2)) MB" -ForegroundColor Gray
    Write-Host "    Primes found:   $rustPrimes" -ForegroundColor Gray
}

if ($standardAvailable -and $aotAvailable) {
    Write-Host "  Performance (C# AOT vs Standard):" -ForegroundColor White
    if ($aotBenchAvg -lt $standardBenchAvg) {
        $improvement = [math]::Round((($standardBenchAvg - $aotBenchAvg) / $standardBenchAvg * 100), 2)
        Write-Host "    Speed:  AOT is ${improvement}% faster" -ForegroundColor Green
    } elseif ($aotBenchAvg -gt $standardBenchAvg) {
        $degradation = [math]::Round((($aotBenchAvg - $standardBenchAvg) / $standardBenchAvg * 100), 2)
        Write-Host "    Speed:  AOT is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Speed:  Same speed" -ForegroundColor White
    }

    $memoryDiff = [math]::Round(($standardMemory - $aotMemory), 2)
    $memoryPercent = [math]::Round((($standardMemory - $aotMemory) / $standardMemory * 100), 2)

    if ($memoryDiff -gt 0) {
        Write-Host "    Memory: AOT uses ${memoryDiff} MB less (${memoryPercent}% reduction)" -ForegroundColor Green
    } elseif ($memoryDiff -lt 0) {
        $memoryIncrease = [math]::Round((([math]::Abs($memoryDiff)) / $standardMemory * 100), 2)
        Write-Host "    Memory: AOT uses $([math]::Abs($memoryDiff)) MB more (${memoryIncrease}% increase)" -ForegroundColor Yellow
    } else {
        Write-Host "    Memory: Same memory usage" -ForegroundColor White
    }
}

if ($standardAvailable -and $javaGraalAvailable) {
    Write-Host "  Performance (Java GraalVM vs C# Standard):" -ForegroundColor White
    if ($javaGraalBenchAvg -lt $standardBenchAvg) {
        $improvement = [math]::Round((($standardBenchAvg - $javaGraalBenchAvg) / $standardBenchAvg * 100), 2)
        Write-Host "    Speed:  Java GraalVM is ${improvement}% faster" -ForegroundColor Green
    } elseif ($javaGraalBenchAvg -gt $standardBenchAvg) {
        $degradation = [math]::Round((($javaGraalBenchAvg - $standardBenchAvg) / $standardBenchAvg * 100), 2)
        Write-Host "    Speed:  Java GraalVM is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Speed:  Same speed" -ForegroundColor White
    }

    $memoryDiff = [math]::Round(($standardMemory - $javaGraalMemory), 2)
    $memoryPercent = [math]::Round((($standardMemory - $javaGraalMemory) / $standardMemory * 100), 2)

    if ($memoryDiff -gt 0) {
        Write-Host "    Memory: Java GraalVM uses ${memoryDiff} MB less (${memoryPercent}% reduction)" -ForegroundColor Green
    } elseif ($memoryDiff -lt 0) {
        $memoryIncrease = [math]::Round((([math]::Abs($memoryDiff)) / $standardMemory * 100), 2)
        Write-Host "    Memory: Java GraalVM uses $([math]::Abs($memoryDiff)) MB more (${memoryIncrease}% increase)" -ForegroundColor Yellow
    } else {
        Write-Host "    Memory: Same memory usage" -ForegroundColor White
    }
}

if ($aotAvailable -and $javaGraalAvailable) {
    Write-Host "  Performance (Java GraalVM vs C# AOT):" -ForegroundColor White
    if ($javaGraalBenchAvg -lt $aotBenchAvg) {
        $improvement = [math]::Round((($aotBenchAvg - $javaGraalBenchAvg) / $aotBenchAvg * 100), 2)
        Write-Host "    Speed:  Java GraalVM is ${improvement}% faster" -ForegroundColor Green
    } elseif ($javaGraalBenchAvg -gt $aotBenchAvg) {
        $degradation = [math]::Round((($javaGraalBenchAvg - $aotBenchAvg) / $aotBenchAvg * 100), 2)
        Write-Host "    Speed:  Java GraalVM is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Speed:  Same speed" -ForegroundColor White
    }

    $memoryDiff = [math]::Round(($aotMemory - $javaGraalMemory), 2)
    $memoryPercent = [math]::Round((($aotMemory - $javaGraalMemory) / $aotMemory * 100), 2)

    if ($memoryDiff -gt 0) {
        Write-Host "    Memory: Java GraalVM uses ${memoryDiff} MB less (${memoryPercent}% reduction)" -ForegroundColor Green
    } elseif ($memoryDiff -lt 0) {
        $memoryIncrease = [math]::Round((([math]::Abs($memoryDiff)) / $aotMemory * 100), 2)
        Write-Host "    Memory: Java GraalVM uses $([math]::Abs($memoryDiff)) MB more (${memoryIncrease}% increase)" -ForegroundColor Yellow
    } else {
        Write-Host "    Memory: Same memory usage" -ForegroundColor White
    }
}

if ($rustAvailable -and $standardAvailable) {
    Write-Host "  Performance (Rust vs C# Standard):" -ForegroundColor White
    if ($rustBenchAvg -lt $standardBenchAvg) {
        $improvement = [math]::Round((($standardBenchAvg - $rustBenchAvg) / $standardBenchAvg * 100), 2)
        Write-Host "    Speed:  Rust is ${improvement}% faster" -ForegroundColor Green
    } elseif ($rustBenchAvg -gt $standardBenchAvg) {
        $degradation = [math]::Round((($rustBenchAvg - $standardBenchAvg) / $standardBenchAvg * 100), 2)
        Write-Host "    Speed:  Rust is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Speed:  Same speed" -ForegroundColor White
    }

    $memoryDiff = [math]::Round(($standardMemory - $rustMemory), 2)
    $memoryPercent = [math]::Round((($standardMemory - $rustMemory) / $standardMemory * 100), 2)

    if ($memoryDiff -gt 0) {
        Write-Host "    Memory: Rust uses ${memoryDiff} MB less (${memoryPercent}% reduction)" -ForegroundColor Green
    } elseif ($memoryDiff -lt 0) {
        $memoryIncrease = [math]::Round((([math]::Abs($memoryDiff)) / $standardMemory * 100), 2)
        Write-Host "    Memory: Rust uses $([math]::Abs($memoryDiff)) MB more (${memoryIncrease}% increase)" -ForegroundColor Yellow
    } else {
        Write-Host "    Memory: Same memory usage" -ForegroundColor White
    }
}

if ($rustAvailable -and $aotAvailable) {
    Write-Host "  Performance (Rust vs C# AOT):" -ForegroundColor White
    if ($rustBenchAvg -lt $aotBenchAvg) {
        $improvement = [math]::Round((($aotBenchAvg - $rustBenchAvg) / $aotBenchAvg * 100), 2)
        Write-Host "    Speed:  Rust is ${improvement}% faster" -ForegroundColor Green
    } elseif ($rustBenchAvg -gt $aotBenchAvg) {
        $degradation = [math]::Round((($rustBenchAvg - $aotBenchAvg) / $aotBenchAvg * 100), 2)
        Write-Host "    Speed:  Rust is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Speed:  Same speed" -ForegroundColor White
    }

    $memoryDiff = [math]::Round(($aotMemory - $rustMemory), 2)
    $memoryPercent = [math]::Round((($aotMemory - $rustMemory) / $aotMemory * 100), 2)

    if ($memoryDiff -gt 0) {
        Write-Host "    Memory: Rust uses ${memoryDiff} MB less (${memoryPercent}% reduction)" -ForegroundColor Green
    } elseif ($memoryDiff -lt 0) {
        $memoryIncrease = [math]::Round((([math]::Abs($memoryDiff)) / $aotMemory * 100), 2)
        Write-Host "    Memory: Rust uses $([math]::Abs($memoryDiff)) MB more (${memoryIncrease}% increase)" -ForegroundColor Yellow
    } else {
        Write-Host "    Memory: Same memory usage" -ForegroundColor White
    }
}

if ($rustAvailable -and $javaGraalAvailable) {
    Write-Host "  Performance (Rust vs Java GraalVM):" -ForegroundColor White
    if ($rustBenchAvg -lt $javaGraalBenchAvg) {
        $improvement = [math]::Round((($javaGraalBenchAvg - $rustBenchAvg) / $javaGraalBenchAvg * 100), 2)
        Write-Host "    Speed:  Rust is ${improvement}% faster" -ForegroundColor Green
    } elseif ($rustBenchAvg -gt $javaGraalBenchAvg) {
        $degradation = [math]::Round((($rustBenchAvg - $javaGraalBenchAvg) / $javaGraalBenchAvg * 100), 2)
        Write-Host "    Speed:  Rust is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "    Speed:  Same speed" -ForegroundColor White
    }

    $memoryDiff = [math]::Round(($javaGraalMemory - $rustMemory), 2)
    $memoryPercent = [math]::Round((($javaGraalMemory - $rustMemory) / $javaGraalMemory * 100), 2)

    if ($memoryDiff -gt 0) {
        Write-Host "    Memory: Rust uses ${memoryDiff} MB less (${memoryPercent}% reduction)" -ForegroundColor Green
    } elseif ($memoryDiff -lt 0) {
        $memoryIncrease = [math]::Round((([math]::Abs($memoryDiff)) / $javaGraalMemory * 100), 2)
        Write-Host "    Memory: Rust uses $([math]::Abs($memoryDiff)) MB more (${memoryIncrease}% increase)" -ForegroundColor Yellow
    } else {
        Write-Host "    Memory: Same memory usage" -ForegroundColor White
    }
}
Write-Host ""

# Detailed statistics table
Write-Host "=== Detailed Statistics ===" -ForegroundColor Cyan
Write-Host ""

$table = @()

if ($standardAvailable) {
    $table += [PSCustomObject]@{
        API = "Standard"
        Endpoint = "/users"
        Min = ($standardUsersTimes | Measure-Object -Minimum).Minimum
        Max = ($standardUsersTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($standardUsersTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($standardUsersTimes | Sort-Object)[[math]::Floor($standardUsersTimes.Count / 2)], 2)
    }

    $table += [PSCustomObject]@{
        API = "Standard"
        Endpoint = "/benchmark"
        Min = ($standardBenchmarkTimes | Measure-Object -Minimum).Minimum
        Max = ($standardBenchmarkTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($standardBenchmarkTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($standardBenchmarkTimes | Sort-Object)[[math]::Floor($standardBenchmarkTimes.Count / 2)], 2)
    }
}

if ($aotAvailable) {
    $table += [PSCustomObject]@{
        API = "C# AOT"
        Endpoint = "/users"
        Min = ($aotUsersTimes | Measure-Object -Minimum).Minimum
        Max = ($aotUsersTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($aotUsersTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($aotUsersTimes | Sort-Object)[[math]::Floor($aotUsersTimes.Count / 2)], 2)
    }

    $table += [PSCustomObject]@{
        API = "C# AOT"
        Endpoint = "/benchmark"
        Min = ($aotBenchmarkTimes | Measure-Object -Minimum).Minimum
        Max = ($aotBenchmarkTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($aotBenchmarkTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($aotBenchmarkTimes | Sort-Object)[[math]::Floor($aotBenchmarkTimes.Count / 2)], 2)
    }
}

if ($javaGraalAvailable) {
    $table += [PSCustomObject]@{
        API = "Java GraalVM"
        Endpoint = "/users"
        Min = ($javaGraalUsersTimes | Measure-Object -Minimum).Minimum
        Max = ($javaGraalUsersTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($javaGraalUsersTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($javaGraalUsersTimes | Sort-Object)[[math]::Floor($javaGraalUsersTimes.Count / 2)], 2)
    }

    $table += [PSCustomObject]@{
        API = "Java GraalVM"
        Endpoint = "/benchmark"
        Min = ($javaGraalBenchmarkTimes | Measure-Object -Minimum).Minimum
        Max = ($javaGraalBenchmarkTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($javaGraalBenchmarkTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($javaGraalBenchmarkTimes | Sort-Object)[[math]::Floor($javaGraalBenchmarkTimes.Count / 2)], 2)
    }
}

if ($rustAvailable) {
    $table += [PSCustomObject]@{
        API = "Rust"
        Endpoint = "/users"
        Min = ($rustUsersTimes | Measure-Object -Minimum).Minimum
        Max = ($rustUsersTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($rustUsersTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($rustUsersTimes | Sort-Object)[[math]::Floor($rustUsersTimes.Count / 2)], 2)
    }

    $table += [PSCustomObject]@{
        API = "Rust"
        Endpoint = "/benchmark"
        Min = ($rustBenchmarkTimes | Measure-Object -Minimum).Minimum
        Max = ($rustBenchmarkTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($rustBenchmarkTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($rustBenchmarkTimes | Sort-Object)[[math]::Floor($rustBenchmarkTimes.Count / 2)], 2)
    }
}

$table | Format-Table -AutoSize

Write-Host "Done!" -ForegroundColor Green
