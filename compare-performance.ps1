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
    param([System.Diagnostics.Process]$Process)

    return [PSCustomObject]@{
        PrivateMemory = [math]::Round($Process.PrivateMemorySize64 / 1MB, 2)
        WorkingSet = [math]::Round($Process.WorkingSet64 / 1MB, 2)
        VirtualMemory = [math]::Round($Process.VirtualMemorySize64 / 1MB, 2)
        PagedMemory = [math]::Round($Process.PagedMemorySize64 / 1MB, 2)
        NonPagedMemory = [math]::Round($Process.NonpagedSystemMemorySize64 / 1KB, 2)
        PeakWorkingSet = [math]::Round($Process.PeakWorkingSet64 / 1MB, 2)
        PeakVirtualMemory = [math]::Round($Process.PeakVirtualMemorySize64 / 1MB, 2)
        PeakPagedMemory = [math]::Round($Process.PeakPagedMemorySize64 / 1MB, 2)
    }
}

if ($standardAvailable) {
    try {
        $result = Invoke-RestMethod -Uri "$StandardUrl/benchmark" -ErrorAction SilentlyContinue
        $standardPid = $result.processId
        $process = Get-Process -Id $result.processId -ErrorAction SilentlyContinue
        if ($process) {
            $standardMetrics = Get-MemoryMetrics -Process $process
            Write-Host "  Standard API (PID: $standardPid)" -ForegroundColor Cyan
            Write-Host "    Private Memory:     $($standardMetrics.PrivateMemory) MB" -ForegroundColor Gray
            Write-Host "    Working Set:        $($standardMetrics.WorkingSet) MB" -ForegroundColor Gray
            Write-Host "    Virtual Memory:     $($standardMetrics.VirtualMemory) MB" -ForegroundColor Gray
            Write-Host "    Paged Memory:       $($standardMetrics.PagedMemory) MB" -ForegroundColor Gray
            Write-Host "    Non-Paged Memory:   $($standardMetrics.NonPagedMemory) KB" -ForegroundColor Gray
            Write-Host "    Peak Working Set:   $($standardMetrics.PeakWorkingSet) MB" -ForegroundColor Gray
            Write-Host "    Peak Virtual:       $($standardMetrics.PeakVirtualMemory) MB" -ForegroundColor Gray
            Write-Host "    Peak Paged:         $($standardMetrics.PeakPagedMemory) MB" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {}
}

if ($aotAvailable) {
    try {
        $result = Invoke-RestMethod -Uri "$AotUrl/benchmark" -ErrorAction SilentlyContinue
        $aotPid = $result.processId
        $process = Get-Process -Id $result.processId -ErrorAction SilentlyContinue
        if ($process) {
            $aotMetrics = Get-MemoryMetrics -Process $process
            Write-Host "  AOT API (PID: $aotPid)" -ForegroundColor Cyan
            Write-Host "    Private Memory:     $($aotMetrics.PrivateMemory) MB" -ForegroundColor Gray
            Write-Host "    Working Set:        $($aotMetrics.WorkingSet) MB" -ForegroundColor Gray
            Write-Host "    Virtual Memory:     $($aotMetrics.VirtualMemory) MB" -ForegroundColor Gray
            Write-Host "    Paged Memory:       $($aotMetrics.PagedMemory) MB" -ForegroundColor Gray
            Write-Host "    Non-Paged Memory:   $($aotMetrics.NonPagedMemory) KB" -ForegroundColor Gray
            Write-Host "    Peak Working Set:   $($aotMetrics.PeakWorkingSet) MB" -ForegroundColor Gray
            Write-Host "    Peak Virtual:       $($aotMetrics.PeakVirtualMemory) MB" -ForegroundColor Gray
            Write-Host "    Peak Paged:         $($aotMetrics.PeakPagedMemory) MB" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {}
}

if ($javaGraalAvailable) {
    try {
        $result = Invoke-RestMethod -Uri "$JavaGraalUrl/benchmark" -ErrorAction SilentlyContinue
        $javaGraalPid = $result.processId
        $process = Get-Process -Id $result.processId -ErrorAction SilentlyContinue
        if ($process) {
            $javaGraalMetrics = Get-MemoryMetrics -Process $process
            Write-Host "  Java GraalVM API (PID: $javaGraalPid)" -ForegroundColor Cyan
            Write-Host "    Private Memory:     $($javaGraalMetrics.PrivateMemory) MB" -ForegroundColor Gray
            Write-Host "    Working Set:        $($javaGraalMetrics.WorkingSet) MB" -ForegroundColor Gray
            Write-Host "    Virtual Memory:     $($javaGraalMetrics.VirtualMemory) MB" -ForegroundColor Gray
            Write-Host "    Paged Memory:       $($javaGraalMetrics.PagedMemory) MB" -ForegroundColor Gray
            Write-Host "    Non-Paged Memory:   $($javaGraalMetrics.NonPagedMemory) KB" -ForegroundColor Gray
            Write-Host "    Peak Working Set:   $($javaGraalMetrics.PeakWorkingSet) MB" -ForegroundColor Gray
            Write-Host "    Peak Virtual:       $($javaGraalMetrics.PeakVirtualMemory) MB" -ForegroundColor Gray
            Write-Host "    Peak Paged:         $($javaGraalMetrics.PeakPagedMemory) MB" -ForegroundColor Gray
            Write-Host ""
        }
    } catch {}
}

# Test 1: Users endpoint response time (JSON serialization heavy)
Write-Host "`n=== Test 1: Users Endpoint (/users - 10k users) ===" -ForegroundColor Cyan
Write-Host ""

if ($standardAvailable) {
    Write-Host "Standard API (PID: $standardPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$StandardUrl/users"
            $sw.Stop()
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Priv: $($standardMetrics.PrivateMemory) MB | WS: $($standardMetrics.WorkingSet) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

if ($aotAvailable) {
    Write-Host "AOT API (PID: $aotPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$AotUrl/users"
            $sw.Stop()
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Priv: $($aotMetrics.PrivateMemory) MB | WS: $($aotMetrics.WorkingSet) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

if ($javaGraalAvailable) {
    Write-Host "Java GraalVM API (PID: $javaGraalPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod -Uri "$JavaGraalUrl/users"
            $sw.Stop()
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Priv: $($javaGraalMetrics.PrivateMemory) MB | WS: $($javaGraalMetrics.WorkingSet) MB" -ForegroundColor Gray
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

if ($standardAvailable) {
    Write-Host "Standard API (PID: $standardPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-RestMethod -Uri "$StandardUrl/benchmark"
            $sw.Stop()
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Primes: $($result.primesFound) | Priv: $($standardMetrics.PrivateMemory) MB | WS: $($standardMetrics.WorkingSet) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

if ($aotAvailable) {
    Write-Host "AOT API (PID: $aotPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-RestMethod -Uri "$AotUrl/benchmark"
            $sw.Stop()
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Primes: $($result.primesFound) | Priv: $($aotMetrics.PrivateMemory) MB | WS: $($aotMetrics.WorkingSet) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

if ($javaGraalAvailable) {
    Write-Host "Java GraalVM API (PID: $javaGraalPid):" -ForegroundColor Green
    for ($i = 1; $i -le $TestRequests; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-RestMethod -Uri "$JavaGraalUrl/benchmark"
            $sw.Stop()
            Write-Host "  Request $i : $($sw.ElapsedMilliseconds) ms | Primes: $($result.primesFound) | Priv: $($javaGraalMetrics.PrivateMemory) MB | WS: $($javaGraalMetrics.WorkingSet) MB" -ForegroundColor Gray
        } catch {
            Write-Host "  Request $i : Failed" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 500
    }
    Write-Host ""
}

Write-Host "Done!" -ForegroundColor Green
