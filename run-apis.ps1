$ErrorActionPreference = "Stop"

$rootPath = $PSScriptRoot
$publishPath = Join-Path $rootPath "publish"

Write-Host ""
Write-Host "=== Starting APIs ===" -ForegroundColor Cyan
Write-Host ""

# Check if publish directory exists
if (-not (Test-Path $publishPath)) {
    Write-Host "Error: Publish directory not found" -ForegroundColor Red
    Write-Host "Please run build-and-run.ps1 first to build the projects" -ForegroundColor Yellow
    exit 1
}

$pids = @()

# Start StandardMinimalApi
$standardBat = Join-Path $publishPath "start-standard.bat"
if (Test-Path $standardBat) {
    Write-Host "Starting StandardMinimalApi on http://localhost:5000" -ForegroundColor Green

    # Start batch file using cmd /c so it detaches
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$standardBat`"" -WindowStyle Hidden

    Start-Sleep -Seconds 2

    # Find the dotnet process
    $dotnetProc = Get-Process -Name dotnet -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*StandardMinimalApi*" } |
        Select-Object -First 1

    if ($dotnetProc) {
        $pids += @{Name="StandardMinimalApi"; PID=$dotnetProc.Id}
    } else {
        Write-Host "  Warning: Could not find StandardMinimalApi process" -ForegroundColor Yellow
    }
} else {
    Write-Host "Warning: start-standard.bat not found at $standardBat" -ForegroundColor Yellow
}

# Start AotMinimalApi
$aotBat = Join-Path $publishPath "start-aot.bat"
if (Test-Path $aotBat) {
    Write-Host "Starting AotMinimalApi on http://localhost:5001" -ForegroundColor Green

    # Start batch file using cmd /c so it detaches
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$aotBat`"" -WindowStyle Hidden

    Start-Sleep -Seconds 2

    # Find the AotMinimalApi process
    $aotProc = Get-Process -Name AotMinimalApi -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($aotProc) {
        $pids += @{Name="AotMinimalApi"; PID=$aotProc.Id}
    } else {
        Write-Host "  Warning: Could not find AotMinimalApi process" -ForegroundColor Yellow
    }
} else {
    Write-Host "Warning: start-aot.bat not found at $aotBat" -ForegroundColor Yellow
}

if ($pids.Count -eq 0) {
    Write-Host ""
    Write-Host "Error: No APIs were started" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== APIs Started ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "StandardMinimalApi: http://localhost:5000" -ForegroundColor White
Write-Host "AotMinimalApi:      http://localhost:5001" -ForegroundColor White
Write-Host ""
Write-Host "APIs are running as detached processes (no parent process)" -ForegroundColor Gray
Write-Host "To stop them, kill the processes by PID or name" -ForegroundColor Gray
Write-Host ""

foreach ($proc in $pids) {
    Write-Host "  $($proc.Name) - PID: $($proc.PID)" -ForegroundColor Gray
}
