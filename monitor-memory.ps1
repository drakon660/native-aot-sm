param(
    [int]$RefreshSeconds = 2
)

function Get-ApiMemoryInfo {
    param(
        [string]$ProcessName,
        [string]$DisplayName,
        [int]$Port
    )

    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue

    if ($processes) {
        foreach ($process in $processes) {
            $workingSet = [math]::Round($process.WorkingSet64 / 1MB, 2)
            $privateMemory = [math]::Round($process.PrivateMemorySize64 / 1MB, 2)

            # Get committed memory (what Task Manager shows as "Memory")
            $committedMemory = [math]::Round(($process.PagedMemorySize64 + $process.NonpagedSystemMemorySize64) / 1MB, 2)

            $cpuPercent = [math]::Round($process.CPU, 2)
            $threads = $process.Threads.Count

            [PSCustomObject]@{
                Name = $DisplayName
                PID = $process.Id
                Port = $Port
                'Memory (MB)' = $privateMemory
                'Working Set (MB)' = $workingSet
                'CPU Time (s)' = $cpuPercent
                Threads = $threads
            }
        }
    }
}

Clear-Host
Write-Host "=== API Memory Monitor ===" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit" -ForegroundColor Yellow
Write-Host "Refresh interval: $RefreshSeconds seconds`n" -ForegroundColor Gray

while ($true) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Clear screen and show header
    Clear-Host
    Write-Host "=== API Memory Monitor - $timestamp ===" -ForegroundColor Cyan
    Write-Host ""

    $apiData = @()

    # Check StandardMinimalApi
    $apiData += Get-ApiMemoryInfo -ProcessName "StandardMinimalApi" -DisplayName "Standard API" -Port 5000

    # Check AotMinimalApi
    $apiData += Get-ApiMemoryInfo -ProcessName "AotMinimalApi" -DisplayName "AOT API" -Port 5001

    # Check Java GraalVM (springbootgraalvm)
    $apiData += Get-ApiMemoryInfo -ProcessName "springbootgraalvm" -DisplayName "Java GraalVM" -Port 5002

    if ($apiData.Count -eq 0) {
        Write-Host "No APIs are currently running" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Expected processes:" -ForegroundColor Gray
        Write-Host "  - StandardMinimalApi.exe (port 5000)" -ForegroundColor Gray
        Write-Host "  - AotMinimalApi.exe (port 5001)" -ForegroundColor Gray
        Write-Host "  - springbootgraalvm.exe (port 5002)" -ForegroundColor Gray
    } else {
        # Display as formatted table
        $apiData | Format-Table -AutoSize

        Write-Host ""
        Write-Host "Legend:" -ForegroundColor Gray
        Write-Host "  Memory:      Private memory (matches Task Manager 'Memory' column)" -ForegroundColor Gray
        Write-Host "  Working Set: Memory in physical RAM (matches Task Manager 'Active private working set')" -ForegroundColor Gray
        Write-Host "  CPU Time:    Total processor time used" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "Press Ctrl+C to exit | Refreshing in $RefreshSeconds seconds..." -ForegroundColor Yellow

    Start-Sleep -Seconds $RefreshSeconds
}
