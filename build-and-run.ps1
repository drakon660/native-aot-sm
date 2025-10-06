param(
    [string]$Project = "both",
    [string]$Configuration = "Release",
    [switch]$CompileOnly,
    [switch]$RunOnly
)

$ErrorActionPreference = "Stop"

$rootPath = $PSScriptRoot
$publishPath = Join-Path $rootPath "publish"

# Validate parameters
if ($CompileOnly -and $RunOnly) {
    Write-Host "Error: Cannot specify both -CompileOnly and -RunOnly" -ForegroundColor Red
    exit 1
}

# Skip build if RunOnly is specified
if (-not $RunOnly) {
    Write-Host "Starting build and publish process..." -ForegroundColor Green

    # Clean publish directory
    if (Test-Path $publishPath) {
        Write-Host "Cleaning publish directory..." -ForegroundColor Yellow
        Remove-Item -Path $publishPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $publishPath -Force | Out-Null

    # Build and publish StandardMinimalApi
    if ($Project -eq "both" -or $Project -eq "standard") {
        Write-Host "`nBuilding StandardMinimalApi..." -ForegroundColor Cyan
        $standardPath = Join-Path $publishPath "StandardMinimalApi"

        dotnet publish "$rootPath\StandardMinimalApi\StandardMinimalApi.csproj" `
            -c $Configuration `
            -o $standardPath `
            --nologo

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to build StandardMinimalApi" -ForegroundColor Red
            exit 1
        }

        Write-Host "StandardMinimalApi published to: $standardPath" -ForegroundColor Green
    }

    # Build and publish AotMinimalApi
    if ($Project -eq "both" -or $Project -eq "aot") {
        Write-Host "`nBuilding AotMinimalApi with Native AOT..." -ForegroundColor Cyan
        $aotPath = Join-Path $publishPath "AotMinimalApi"

        dotnet publish "$rootPath\AotMinimalApi\AotMinimalApi.csproj" `
            -c $Configuration `
            -o $aotPath `
            --nologo

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to build AotMinimalApi (Native AOT requires Visual Studio C++ tools)" -ForegroundColor Red
            Write-Host "Continuing with Standard API only..." -ForegroundColor Yellow
        } else {
            Write-Host "AotMinimalApi published to: $aotPath" -ForegroundColor Green
        }
    }

    Write-Host "`n=== Build Complete ===" -ForegroundColor Green
    Write-Host "Published binaries are in: $publishPath" -ForegroundColor White
}

# Exit early if CompileOnly is specified
if ($CompileOnly) {
    exit 0
}

# Ask user which API to run
Write-Host "`nWhich API would you like to run?" -ForegroundColor Yellow
Write-Host "1. StandardMinimalApi (port 5000)" -ForegroundColor White
Write-Host "2. AotMinimalApi (port 5001)" -ForegroundColor White
Write-Host "3. Both (parallel)" -ForegroundColor White
Write-Host "4. Exit" -ForegroundColor White

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        $standardPath = Join-Path $publishPath "StandardMinimalApi"
        if (-not (Test-Path $standardPath)) {
            Write-Host "`nError: StandardMinimalApi was not published successfully." -ForegroundColor Red
            Write-Host "Please run the script again with -Project standard to build it." -ForegroundColor Yellow
            exit 1
        }
        Write-Host "`n=== Starting StandardMinimalApi ===" -ForegroundColor Cyan
        Write-Host "URL: http://localhost:5000" -ForegroundColor White
        Write-Host "Endpoints:" -ForegroundColor White
        Write-Host "  - http://localhost:5000/users" -ForegroundColor Gray
        Write-Host "  - http://localhost:5000/benchmark" -ForegroundColor Gray
        Write-Host "  - http://localhost:5000/openapi/v1.json (Dev only)" -ForegroundColor Gray
        Write-Host "`nStarting application...`n" -ForegroundColor Yellow

        $env:ASPNETCORE_URLS = "http://localhost:5000"
        Set-Location $standardPath
        & dotnet StandardMinimalApi.dll
    }
    "2" {
        $aotPath = Join-Path $publishPath "AotMinimalApi"
        if (-not (Test-Path $aotPath)) {
            Write-Host "`nError: AotMinimalApi was not published successfully." -ForegroundColor Red
            Write-Host "Please run the script again with -Project aot to build it." -ForegroundColor Yellow
            exit 1
        }
        Write-Host "`n=== Starting AotMinimalApi (Native AOT) ===" -ForegroundColor Cyan
        Write-Host "URL: http://localhost:5001" -ForegroundColor White
        Write-Host "Endpoints:" -ForegroundColor White
        Write-Host "  - http://localhost:5001/users" -ForegroundColor Gray
        Write-Host "  - http://localhost:5001/benchmark" -ForegroundColor Gray
        Write-Host "  - http://localhost:5001/openapi/v1.json (Dev only)" -ForegroundColor Gray
        Write-Host "`nStarting application...`n" -ForegroundColor Yellow

        $env:ASPNETCORE_URLS = "http://localhost:5001"
        Set-Location $aotPath
        & .\AotMinimalApi.exe
    }
    "3" {
        Write-Host "`n=== Starting Both APIs ===" -ForegroundColor Cyan

        $standardPath = Join-Path $publishPath "StandardMinimalApi"
        $aotPath = Join-Path $publishPath "AotMinimalApi"

        # Check both paths exist
        $standardExists = Test-Path $standardPath
        $aotExists = Test-Path $aotPath

        if (-not $standardExists -and -not $aotExists) {
            Write-Host "`nError: Neither API was published successfully." -ForegroundColor Red
            Write-Host "Please run the script again to build them." -ForegroundColor Yellow
            exit 1
        }

        # Start StandardMinimalApi in background
        if ($standardExists) {
            Write-Host "`nStarting StandardMinimalApi..." -ForegroundColor Cyan

            $standardJob = Start-Job -ScriptBlock {
                param($path)
                Set-Location $path
                $env:ASPNETCORE_URLS = "http://localhost:5000"
                & dotnet StandardMinimalApi.dll
            } -ArgumentList $standardPath

            # Wait for API to start (with retry)
            $maxRetries = 10
            $retryCount = 0
            $standardPid = 0

            while ($retryCount -lt $maxRetries) {
                Start-Sleep -Milliseconds 500
                try {
                    $response = Invoke-RestMethod -Uri "http://localhost:5000/benchmark" -TimeoutSec 2 -ErrorAction Stop
                    $standardPid = $response.processId
                    Write-Host "  [OK] StandardMinimalApi running on http://localhost:5000 (PID: $standardPid, Job ID: $($standardJob.Id))" -ForegroundColor Green
                    break
                } catch {
                    $retryCount++
                }
            }

            if ($standardPid -eq 0) {
                if ($standardJob.State -eq "Running") {
                    Write-Host "  [WARNING] StandardMinimalApi starting... (Job ID: $($standardJob.Id))" -ForegroundColor Yellow
                } else {
                    Write-Host "  [ERROR] StandardMinimalApi failed to start" -ForegroundColor Red
                    Receive-Job $standardJob
                }
            }
        } else {
            Write-Host "`n  [SKIP] StandardMinimalApi not published" -ForegroundColor Yellow
        }

        # Start AotMinimalApi in background
        if ($aotExists) {
            Write-Host "`nStarting AotMinimalApi (Native AOT)..." -ForegroundColor Cyan

            $aotJob = Start-Job -ScriptBlock {
                param($path)
                Set-Location $path
                $env:ASPNETCORE_URLS = "http://localhost:5001"
                & .\AotMinimalApi.exe
            } -ArgumentList $aotPath

            # Wait for API to start (with retry)
            $maxRetries = 10
            $retryCount = 0
            $aotPid = 0

            while ($retryCount -lt $maxRetries) {
                Start-Sleep -Milliseconds 500
                try {
                    $response = Invoke-RestMethod -Uri "http://localhost:5001/benchmark" -TimeoutSec 2 -ErrorAction Stop
                    $aotPid = $response.processId
                    Write-Host "  [OK] AotMinimalApi running on http://localhost:5001 (PID: $aotPid, Job ID: $($aotJob.Id))" -ForegroundColor Green
                    break
                } catch {
                    $retryCount++
                }
            }

            if ($aotPid -eq 0) {
                if ($aotJob.State -eq "Running") {
                    Write-Host "  [WARNING] AotMinimalApi starting... (Job ID: $($aotJob.Id))" -ForegroundColor Yellow
                } else {
                    Write-Host "  [ERROR] AotMinimalApi failed to start" -ForegroundColor Red
                    Receive-Job $aotJob
                }
            }
        } else {
            Write-Host "`n  [SKIP] AotMinimalApi not published" -ForegroundColor Yellow
        }

        Write-Host "`n=== APIs Running ===" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop all APIs...`n" -ForegroundColor Yellow

        if ($standardExists) {
            Write-Host "StandardMinimalApi Endpoints:" -ForegroundColor White
            Write-Host "  - http://localhost:5000/users" -ForegroundColor Gray
            Write-Host "  - http://localhost:5000/benchmark" -ForegroundColor Gray
            Write-Host "  - http://localhost:5000/openapi/v1.json (Dev only)" -ForegroundColor Gray
            Write-Host ""
        }

        if ($aotExists) {
            Write-Host "AotMinimalApi Endpoints:" -ForegroundColor White
            Write-Host "  - http://localhost:5001/users" -ForegroundColor Gray
            Write-Host "  - http://localhost:5001/benchmark" -ForegroundColor Gray
            Write-Host "  - http://localhost:5001/openapi/v1.json (Dev only)" -ForegroundColor Gray
            Write-Host ""
        }

        try {
            while ($true) {
                Start-Sleep -Seconds 1

                # Check if jobs are still running
                $anyRunning = $false
                if ($standardExists -and $standardJob.State -eq "Running") { $anyRunning = $true }
                if ($aotExists -and $aotJob.State -eq "Running") { $anyRunning = $true }

                if (-not $anyRunning) {
                    Write-Host "`nAll APIs have stopped" -ForegroundColor Yellow
                    break
                }
            }
        }
        finally {
            Write-Host "`nStopping APIs..." -ForegroundColor Yellow
            if ($standardExists) { Stop-Job -Job $standardJob -ErrorAction SilentlyContinue; Remove-Job -Job $standardJob -ErrorAction SilentlyContinue }
            if ($aotExists) { Stop-Job -Job $aotJob -ErrorAction SilentlyContinue; Remove-Job -Job $aotJob -ErrorAction SilentlyContinue }
            Write-Host "APIs stopped" -ForegroundColor Green
        }
    }
    "4" {
        Write-Host "Exiting..." -ForegroundColor Yellow
        exit 0
    }
    default {
        Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
        exit 1
    }
}
