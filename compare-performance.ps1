param(
    [string]$StandardUrl = "http://localhost:5000",
    [string]$AotUrl = "http://localhost:5001",
    [int]$WarmupRequests = 5,
    [int]$TestRequests = 20
)

Write-Host "=== Comprehensive Performance Comparison: Standard vs Native AOT ===" -ForegroundColor Cyan
Write-Host ""

# Check if APIs are running
Write-Host "Checking API availability..." -ForegroundColor Yellow
$standardAvailable = $false
$aotAvailable = $false

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

if (-not $standardAvailable -and -not $aotAvailable) {
    Write-Host "`nError: Neither API is running. Please start them first." -ForegroundColor Red
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

# Test 2: CPU-intensive benchmark
Write-Host "`n=== Test 2: CPU-Intensive Benchmark (/benchmark - Prime calculation) ===" -ForegroundColor Cyan
Write-Host ""

if ($standardAvailable) {
    Write-Host "Testing Standard API..." -ForegroundColor Green
    $standardBenchmarkTimes = @()
    $standardMemory = 0
    $standardPrimes = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$StandardUrl/benchmark"
            $standardBenchmarkTimes += $result.executionTimeMs
            $standardMemory = $result.workingSetMB
            $standardPrimes = $result.primesFound
            Write-Host "  Request $i : $($result.executionTimeMs) ms" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
    }
}

if ($aotAvailable) {
    Write-Host "`nTesting AOT API..." -ForegroundColor Green
    $aotBenchmarkTimes = @()
    $aotMemory = 0
    $aotPrimes = 0
    for ($i = 1; $i -le $TestRequests; $i++) {
        try {
            $result = Invoke-RestMethod -Uri "$AotUrl/benchmark"
            $aotBenchmarkTimes += $result.executionTimeMs
            $aotMemory = $result.workingSetMB
            $aotPrimes = $result.primesFound
            Write-Host "  Request $i : $($result.executionTimeMs) ms" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
    }
}

# Calculate statistics
Write-Host "`n=== Results Summary ===" -ForegroundColor Cyan
Write-Host ""

# Users endpoint statistics
if ($standardAvailable -and $aotAvailable) {
    Write-Host "Users Endpoint (/users - 10k users, JSON serialization):" -ForegroundColor Yellow

    $standardUsersAvg = ($standardUsersTimes | Measure-Object -Average).Average
    $aotUsersAvg = ($aotUsersTimes | Measure-Object -Average).Average
    $usersSpeedup = [math]::Round(($standardUsersAvg / $aotUsersAvg), 2)

    Write-Host "  Standard API:" -ForegroundColor White
    Write-Host "    Response time: $([math]::Round($standardUsersAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Response size: $([math]::Round($standardUsersSize / 1024 / 1024, 2)) MB" -ForegroundColor Gray

    Write-Host "  AOT API:" -ForegroundColor White
    Write-Host "    Response time: $([math]::Round($aotUsersAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Response size: $([math]::Round($aotUsersSize / 1024 / 1024, 2)) MB" -ForegroundColor Gray

    if ($aotUsersAvg -lt $standardUsersAvg) {
        $improvement = [math]::Round((($standardUsersAvg - $aotUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "  Performance:  AOT is ${improvement}% faster" -ForegroundColor Green
    } elseif ($aotUsersAvg -gt $standardUsersAvg) {
        $degradation = [math]::Round((($aotUsersAvg - $standardUsersAvg) / $standardUsersAvg * 100), 2)
        Write-Host "  Performance:  AOT is ${degradation}% slower" -ForegroundColor Yellow
    } else {
        Write-Host "  Performance:  Same speed" -ForegroundColor White
    }
    Write-Host ""
}

# Benchmark statistics
if ($standardAvailable -and $aotAvailable) {
    Write-Host "CPU-Intensive Benchmark (/benchmark):" -ForegroundColor Yellow

    $standardBenchAvg = ($standardBenchmarkTimes | Measure-Object -Average).Average
    $aotBenchAvg = ($aotBenchmarkTimes | Measure-Object -Average).Average
    $benchSpeedup = [math]::Round(($standardBenchAvg / $aotBenchAvg), 2)

    Write-Host "  Standard API:" -ForegroundColor White
    Write-Host "    Execution time: $([math]::Round($standardBenchAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Memory usage:   $([math]::Round($standardMemory, 2)) MB" -ForegroundColor Gray
    Write-Host "    Primes found:   $standardPrimes" -ForegroundColor Gray

    Write-Host "  AOT API:" -ForegroundColor White
    Write-Host "    Execution time: $([math]::Round($aotBenchAvg, 2)) ms (avg)" -ForegroundColor Gray
    Write-Host "    Memory usage:   $([math]::Round($aotMemory, 2)) MB" -ForegroundColor Gray
    Write-Host "    Primes found:   $aotPrimes" -ForegroundColor Gray

    Write-Host "  Performance:" -ForegroundColor White
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
    Write-Host ""
}

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
        API = "AOT"
        Endpoint = "/users"
        Min = ($aotUsersTimes | Measure-Object -Minimum).Minimum
        Max = ($aotUsersTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($aotUsersTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($aotUsersTimes | Sort-Object)[[math]::Floor($aotUsersTimes.Count / 2)], 2)
    }

    $table += [PSCustomObject]@{
        API = "AOT"
        Endpoint = "/benchmark"
        Min = ($aotBenchmarkTimes | Measure-Object -Minimum).Minimum
        Max = ($aotBenchmarkTimes | Measure-Object -Maximum).Maximum
        Avg = [math]::Round(($aotBenchmarkTimes | Measure-Object -Average).Average, 2)
        Median = [math]::Round(($aotBenchmarkTimes | Sort-Object)[[math]::Floor($aotBenchmarkTimes.Count / 2)], 2)
    }
}

$table | Format-Table -AutoSize

Write-Host "Done!" -ForegroundColor Green
