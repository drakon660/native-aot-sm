param(
    [string]$StandardUrl = "http://localhost:5000",
    [string]$AotUrl = "http://localhost:5001",
    [string]$JavaGraalUrl = "http://localhost:5002",
    [int]$TestRequests = 10
)

Write-Host "=== Comprehensive Performance Comparison: Standard vs Native AOT vs Java GraalVM ===" -ForegroundColor Cyan
Write-Host ""

# Check if APIs are running
Write-Host "Checking API availability..." -ForegroundColor Yellow
$standardAvailable = $false
$aotAvailable = $false
$javaGraalAvailable = $false

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

if (-not $standardAvailable -and -not $aotAvailable -and -not $javaGraalAvailable) {
    Write-Host "`nError: No APIs are running. Please start them first." -ForegroundColor Red
    Write-Host "`nTip: Run the APIs using:" -ForegroundColor Yellow
    Write-Host "  .\build-and-run.ps1 -RunOnly" -ForegroundColor White
    Write-Host "or build and run them with:" -ForegroundColor Yellow
    Write-Host "  .\build-and-run.ps1" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Test Configuration:" -ForegroundColor Yellow
Write-Host "  Test requests: $TestRequests"
Write-Host ""

# Measure baseline memory before any heavy load
Write-Host "Measuring baseline memory..." -ForegroundColor Yellow
Write-Host ""

# Store memory metrics for each API
$standardMetrics = $null
$standardPid = 0
$aotMetrics = $null
$aotPid = 0
$javaGraalMetrics = $null
$javaGraalPid = 0

function Get-MemoryMetrics {
    param([int]$ProcessId)

    # Get metrics from CIM (Windows Performance Counters)
    $cimProcess = Get-CimInstance -Class Win32_PerfFormattedData_PerfProc_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.IDProcess -eq $ProcessId } |
        Select-Object -First 1

    if (-not $cimProcess) {
        return $null
    }

    return [PSCustomObject]@{
        PrivateBytes = [math]::Round($cimProcess.PrivateBytes / 1MB, 2)
        WorkingSetPrivate = [math]::Round($cimProcess.WorkingSetPrivate / 1MB, 2)
    }
}

if ($standardAvailable) {
    try {
        $result = Invoke-RestMethod -Uri "$StandardUrl/benchmark" -ErrorAction SilentlyContinue
        $standardPid = $result.processId
        $standardMetrics = Get-MemoryMetrics -ProcessId $standardPid
        if ($standardMetrics) {
            Write-Host "  Standard API (PID: $standardPid)" -ForegroundColor Cyan
            Write-Host "    Private Bytes:         $($standardMetrics.PrivateBytes) MB" -ForegroundColor Gray
            Write-Host "    Working Set Private:   $($standardMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {}
}

if ($aotAvailable) {
    try {
        $result = Invoke-RestMethod -Uri "$AotUrl/benchmark" -ErrorAction SilentlyContinue
        $aotPid = $result.processId
        $aotMetrics = Get-MemoryMetrics -ProcessId $aotPid
        if ($aotMetrics) {
            Write-Host "  AOT API (PID: $aotPid)" -ForegroundColor Cyan
            Write-Host "    Private Bytes:         $($aotMetrics.PrivateBytes) MB" -ForegroundColor Gray
            Write-Host "    Working Set Private:   $($aotMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {}
}

if ($javaGraalAvailable) {
    try {
        $result = Invoke-RestMethod -Uri "$JavaGraalUrl/benchmark" -ErrorAction SilentlyContinue
        $javaGraalPid = $result.processId
        $javaGraalMetrics = Get-MemoryMetrics -ProcessId $javaGraalPid
        if ($javaGraalMetrics) {
            Write-Host "  Java GraalVM API (PID: $javaGraalPid)" -ForegroundColor Cyan
            Write-Host "    Private Bytes:         $($javaGraalMetrics.PrivateBytes) MB" -ForegroundColor Gray
            Write-Host "    Working Set Private:   $($javaGraalMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {}
}

# Test 1: Users endpoint response time (JSON serialization heavy)
Write-Host "`n=== Test 1: Users Endpoint (/users - 10k users) ===" -ForegroundColor Cyan
Write-Host ""

$standardUsersTimes = @()
$standardUsersMemPriv = @()
$standardUsersMemWSP = @()

if ($standardAvailable) {
    Write-Host "Standard API (PID: $standardPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$StandardUrl/users"
            $sw.Stop()
            $currentMetrics = Get-MemoryMetrics -ProcessId $standardPid
            $standardUsersTimes += $sw.ElapsedMilliseconds
            $standardUsersMemPriv += $currentMetrics.PrivateBytes
            $standardUsersMemWSP += $currentMetrics.WorkingSetPrivate
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Priv: $($currentMetrics.PrivateBytes) MB | WSP: $($currentMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

$aotUsersTimes = @()
$aotUsersMemPriv = @()
$aotUsersMemWSP = @()

if ($aotAvailable) {
    Write-Host "AOT API (PID: $aotPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$AotUrl/users"
            $sw.Stop()
            $currentMetrics = Get-MemoryMetrics -ProcessId $aotPid
            $aotUsersTimes += $sw.ElapsedMilliseconds
            $aotUsersMemPriv += $currentMetrics.PrivateBytes
            $aotUsersMemWSP += $currentMetrics.WorkingSetPrivate
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Priv: $($currentMetrics.PrivateBytes) MB | WSP: $($currentMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

$javaGraalUsersTimes = @()
$javaGraalUsersMemPriv = @()
$javaGraalUsersMemWSP = @()

if ($javaGraalAvailable) {
    Write-Host "Java GraalVM API (PID: $javaGraalPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$JavaGraalUrl/users"
            $sw.Stop()
            $currentMetrics = Get-MemoryMetrics -ProcessId $javaGraalPid
            $javaGraalUsersTimes += $sw.ElapsedMilliseconds
            $javaGraalUsersMemPriv += $currentMetrics.PrivateBytes
            $javaGraalUsersMemWSP += $currentMetrics.WorkingSetPrivate
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Priv: $($currentMetrics.PrivateBytes) MB | WSP: $($currentMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

# Test 2: CPU-intensive benchmark
Write-Host "`n=== Test 2: CPU-Intensive Benchmark (/benchmark - Prime calculation) ===" -ForegroundColor Cyan
Write-Host ""

$standardBenchTimes = @()
$standardBenchMemPriv = @()
$standardBenchMemWSP = @()

if ($standardAvailable) {
    Write-Host "Standard API (PID: $standardPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-RestMethod -Uri "$StandardUrl/benchmark"
            $sw.Stop()
            $currentMetrics = Get-MemoryMetrics -ProcessId $standardPid
            $standardBenchTimes += $sw.ElapsedMilliseconds
            $standardBenchMemPriv += $currentMetrics.PrivateBytes
            $standardBenchMemWSP += $currentMetrics.WorkingSetPrivate
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Primes: $($result.primesFound) | Priv: $($currentMetrics.PrivateBytes) MB | WSP: $($currentMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

$aotBenchTimes = @()
$aotBenchMemPriv = @()
$aotBenchMemWSP = @()

if ($aotAvailable) {
    Write-Host "AOT API (PID: $aotPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-RestMethod -Uri "$AotUrl/benchmark"
            $sw.Stop()
            $currentMetrics = Get-MemoryMetrics -ProcessId $aotPid
            $aotBenchTimes += $sw.ElapsedMilliseconds
            $aotBenchMemPriv += $currentMetrics.PrivateBytes
            $aotBenchMemWSP += $currentMetrics.WorkingSetPrivate
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Primes: $($result.primesFound) | Priv: $($currentMetrics.PrivateBytes) MB | WSP: $($currentMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

$javaGraalBenchTimes = @()
$javaGraalBenchMemPriv = @()
$javaGraalBenchMemWSP = @()

if ($javaGraalAvailable) {
    Write-Host "Java GraalVM API (PID: $javaGraalPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-RestMethod -Uri "$JavaGraalUrl/benchmark"
            $sw.Stop()
            $currentMetrics = Get-MemoryMetrics -ProcessId $javaGraalPid
            $javaGraalBenchTimes += $sw.ElapsedMilliseconds
            $javaGraalBenchMemPriv += $currentMetrics.PrivateBytes
            $javaGraalBenchMemWSP += $currentMetrics.WorkingSetPrivate
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Primes: $($result.primesFound) | Priv: $($currentMetrics.PrivateBytes) MB | WSP: $($currentMetrics.WorkingSetPrivate) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

# Summary - Final memory after all tests
Write-Host "`n=== Performance Summary ===" -ForegroundColor Cyan
Write-Host ""

function Get-Stats {
    param([array]$values)
    if ($values.Count -eq 0) { return $null }
    $avg = ($values | Measure-Object -Average).Average
    $min = ($values | Measure-Object -Minimum).Minimum
    $max = ($values | Measure-Object -Maximum).Maximum
    return [PSCustomObject]@{
        Avg = [math]::Round($avg, 2)
        Min = [math]::Round($min, 2)
        Max = [math]::Round($max, 2)
    }
}

Write-Host "Response Time Summary:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Users Endpoint (/users):" -ForegroundColor White
if ($standardAvailable -and $standardUsersTimes.Count -gt 0) {
    $stats = Get-Stats -values $standardUsersTimes
    Write-Host "    Standard API: Avg=$($stats.Avg)ms, Min=$($stats.Min)ms, Max=$($stats.Max)ms" -ForegroundColor Gray
}
if ($aotAvailable -and $aotUsersTimes.Count -gt 0) {
    $stats = Get-Stats -values $aotUsersTimes
    Write-Host "    AOT API:      Avg=$($stats.Avg)ms, Min=$($stats.Min)ms, Max=$($stats.Max)ms" -ForegroundColor Gray
}
if ($javaGraalAvailable -and $javaGraalUsersTimes.Count -gt 0) {
    $stats = Get-Stats -values $javaGraalUsersTimes
    Write-Host "    Java GraalVM: Avg=$($stats.Avg)ms, Min=$($stats.Min)ms, Max=$($stats.Max)ms" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  CPU Benchmark (/benchmark):" -ForegroundColor White
if ($standardAvailable -and $standardBenchTimes.Count -gt 0) {
    $stats = Get-Stats -values $standardBenchTimes
    Write-Host "    Standard API: Avg=$($stats.Avg)ms, Min=$($stats.Min)ms, Max=$($stats.Max)ms" -ForegroundColor Gray
}
if ($aotAvailable -and $aotBenchTimes.Count -gt 0) {
    $stats = Get-Stats -values $aotBenchTimes
    Write-Host "    AOT API:      Avg=$($stats.Avg)ms, Min=$($stats.Min)ms, Max=$($stats.Max)ms" -ForegroundColor Gray
}
if ($javaGraalAvailable -and $javaGraalBenchTimes.Count -gt 0) {
    $stats = Get-Stats -values $javaGraalBenchTimes
    Write-Host "    Java GraalVM: Avg=$($stats.Avg)ms, Min=$($stats.Min)ms, Max=$($stats.Max)ms" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Final Memory After All Tests:" -ForegroundColor Yellow
if ($standardAvailable) {
    $finalMem = Get-MemoryMetrics -ProcessId $standardPid
    if ($finalMem) {
        Write-Host "  Standard API (PID: $standardPid)" -ForegroundColor Green
        Write-Host "    Private Bytes:       $($finalMem.PrivateBytes) MB" -ForegroundColor Gray
        Write-Host "    Working Set Private: $($finalMem.WorkingSetPrivate) MB" -ForegroundColor Gray
        Write-Host ""
    }
}
if ($aotAvailable) {
    $finalMem = Get-MemoryMetrics -ProcessId $aotPid
    if ($finalMem) {
        Write-Host "  AOT API (PID: $aotPid)" -ForegroundColor Green
        Write-Host "    Private Bytes:       $($finalMem.PrivateBytes) MB" -ForegroundColor Gray
        Write-Host "    Working Set Private: $($finalMem.WorkingSetPrivate) MB" -ForegroundColor Gray
        Write-Host ""
    }
}
if ($javaGraalAvailable) {
    $finalMem = Get-MemoryMetrics -ProcessId $javaGraalPid
    if ($finalMem) {
        Write-Host "  Java GraalVM API (PID: $javaGraalPid)" -ForegroundColor Green
        Write-Host "    Private Bytes:       $($finalMem.PrivateBytes) MB" -ForegroundColor Gray
        Write-Host "    Working Set Private: $($finalMem.WorkingSetPrivate) MB" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "Done!" -ForegroundColor Green
