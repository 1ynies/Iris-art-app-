# Build and run Iris Designer with OpenCV so circling (Cut & Apply) works.
# Uses vcpkg to install opencv4:x64-windows if needed, sets OpenCV_DIR, then runs the app.
# Requires: Visual Studio Build Tools or VS with C++ workload, Git (for cloning vcpkg).

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

function Stop-IrisDesignerIfRunning {
    foreach ($n in @("iris_designer")) {
        $procs = Get-Process -Name $n -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            Write-Host "Stopping $n (PID $($p.Id)) so build folder can be cleared..."
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        }
    }
    if (Get-Process -Name "iris_designer" -ErrorAction SilentlyContinue) { Start-Sleep -Seconds 1 }
    Start-Sleep -Seconds 2
}

function Clear-BuildWindows {
    param([string]$root)
    $buildDir = Join-Path $root "build\windows"
    if (-not (Test-Path $buildDir)) { return $true }
    Stop-IrisDesignerIfRunning
    try {
        Remove-Item -Path $buildDir -Recurse -Force -ErrorAction Stop
        Write-Host "Cleared build/windows."
        return $true
    } catch {
        Write-Host "Could not remove build/windows (file in use). Trying flutter clean anyway..."
        return $false
    }
}

function Test-OpenCVDir {
    param([string]$dir)
    if (-not $dir -or -not (Test-Path -LiteralPath $dir -PathType Container)) { return $false }
    $cfg = Join-Path $dir "OpenCVConfig.cmake"
    $cfg4 = Join-Path $dir "opencv4\OpenCVConfig.cmake"
    return (Test-Path -LiteralPath $cfg) -or (Test-Path -LiteralPath $cfg4)
}

function Get-OpenCVDirFromVcpkg {
    param([string]$vcpkgRoot)
    $base = $vcpkgRoot
    if (Test-Path (Join-Path $vcpkgRoot "installed\x64-windows\share\opencv4\OpenCVConfig.cmake")) {
        return (Join-Path $vcpkgRoot "installed\x64-windows\share\opencv4")
    }
    if (Test-Path (Join-Path $vcpkgRoot "installed\x64-windows\share\opencv\OpenCVConfig.cmake")) {
        return (Join-Path $vcpkgRoot "installed\x64-windows\share\opencv")
    }
    return $null
}

# Helper: get vcpkg bin dir from OpenCV share dir (e.g. .../share/opencv4 -> .../x64-windows/bin)
function Get-VcpkgBinFromOpenCvDir {
    param([string]$openCvDir)
    if (-not $openCvDir) { return $null }
    $tripletDir = Split-Path (Split-Path $openCvDir -Parent) -Parent
    $vcpkgBin = Join-Path $tripletDir "bin"
    if (Test-Path $vcpkgBin -PathType Container) { return $vcpkgBin }
    return $null
}

# Helper: prepend vcpkg bin to PATH so OpenCV DLLs are found when exe runs
function Add-VcpkgBinToPath {
    param([string]$openCvDir)
    $vcpkgBin = Get-VcpkgBinFromOpenCvDir $openCvDir
    if ($vcpkgBin) {
        $env:PATH = "$vcpkgBin;$env:PATH"
        Write-Host "Prepending to PATH (for OpenCV DLLs): $vcpkgBin"
    }
}

# Copy vcpkg bin/*.dll into runner output dirs so iris_engine.dll can load (OpenCV deps).
# Call before "flutter run" when runner dirs already exist; avoids "Iris Engine not available".
function Copy-VcpkgDllsToRunner {
    param([string]$openCvDir, [string]$root)
    $vcpkgBin = Get-VcpkgBinFromOpenCvDir $openCvDir
    if (-not $vcpkgBin) { return }
    $runnerBase = Join-Path $root "build\windows\x64\runner"
    foreach ($cfg in @("Debug", "Release")) {
        $dest = Join-Path $runnerBase $cfg
        if (Test-Path $dest -PathType Container) {
            $dlls = Get-ChildItem -Path $vcpkgBin -Filter "*.dll" -ErrorAction SilentlyContinue
            if ($dlls) {
                Copy-Item -Path $dlls.FullName -Destination $dest -Force
                Write-Host "Copied $($dlls.Count) vcpkg DLLs to $dest"
            }
        }
    }
}

# 1) Use existing OpenCV_DIR if valid
if ($env:OpenCV_DIR) {
    $d = $env:OpenCV_DIR.TrimEnd('\', '/')
    if (Test-OpenCVDir $d) {
        Write-Host "Using existing OpenCV_DIR: $d"
        $env:OpenCV_DIR = $d
        Add-VcpkgBinToPath $d
        Set-Location $ProjectRoot
        Clear-BuildWindows $ProjectRoot | Out-Null
        flutter clean
        flutter pub get
        flutter build windows --debug
        Copy-VcpkgDllsToRunner -openCvDir $d -root $ProjectRoot
        flutter run -d windows
        exit 0
    }
}

# 2) Find or create vcpkg
$vcpkgRoot = $env:VCPKG_ROOT
$vcpkgExe = $null
if ($vcpkgRoot -and (Test-Path $vcpkgRoot)) {
    $vcpkgExe = Join-Path $vcpkgRoot "vcpkg.exe"
    if (-not (Test-Path $vcpkgExe)) { $vcpkgExe = Join-Path $vcpkgRoot "vcpkg" }
    if (Test-Path $vcpkgExe) {
        Write-Host "Using vcpkg at: $vcpkgRoot"
    } else {
        $vcpkgRoot = $null
    }
}
if (-not $vcpkgRoot) {
    $localVcpkg = Join-Path $ProjectRoot ".vcpkg"
    $vcpkgExe = Join-Path $localVcpkg "vcpkg.exe"
    if (Test-Path $vcpkgExe) {
        $vcpkgRoot = $localVcpkg
        $env:VCPKG_ROOT = $vcpkgRoot
        Write-Host "Using project vcpkg: $vcpkgRoot"
    } elseif (Test-Path (Join-Path $localVcpkg "vcpkg")) {
        $vcpkgExe = Join-Path $localVcpkg "vcpkg"
        $vcpkgRoot = $localVcpkg
        $env:VCPKG_ROOT = $vcpkgRoot
        Write-Host "Using project vcpkg: $vcpkgRoot"
    } else {
        Write-Host "vcpkg not found. Cloning vcpkg into .vcpkg (one-time)..."
        New-Item -ItemType Directory -Path $localVcpkg -Force | Out-Null
        Push-Location $localVcpkg
        try {
            git clone --depth 1 https://github.com/microsoft/vcpkg.git .
            if (-not (Test-Path "bootstrap-vcpkg.bat") -and -not (Test-Path "bootstrap-vcpkg.sh")) {
                Write-Host "Git clone failed or produced no files (check internet and proxy)."
                Write-Host "Either run this script where you have internet, or set OpenCV_DIR yourself:"
                Write-Host "  $env:OpenCV_DIR = 'C:\path\to\opencv\build'"
                Write-Host "  flutter clean; flutter pub get; flutter run -d windows"
                exit 1
            }
            if ($IsWindows -or $env:OS -eq "Windows_NT") {
                cmd /c bootstrap-vcpkg.bat
            } else {
                bash ./bootstrap-vcpkg.sh
            }
            $vcpkgRoot = (Get-Location).Path
            $vcpkgExe = Join-Path $vcpkgRoot "vcpkg.exe"
            if (-not (Test-Path $vcpkgExe)) { $vcpkgExe = Join-Path $vcpkgRoot "vcpkg" }
            $env:VCPKG_ROOT = $vcpkgRoot
            Write-Host "vcpkg ready at: $vcpkgRoot"
        } finally {
            Pop-Location
        }
    }
}

# 3) Ensure opencv4 is installed and get OpenCV_DIR
$ocvDir = Get-OpenCVDirFromVcpkg $vcpkgRoot
if (-not $ocvDir) {
    $ocvPkgs = @("opencv4:x64-windows", "opencv4[core,jpeg,png,tiff,webp,thread]:x64-windows")
    $installed = $false
    foreach ($pkg in $ocvPkgs) {
        Write-Host "Installing $pkg via vcpkg (this can take 10-30 min on first run)..."
        & $vcpkgExe install $pkg 2>&1 | Tee-Object -Variable vcpkgOut | Out-Host
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
            break
        }
        $outStr = $vcpkgOut | Out-String
        if ($outStr -match "Access is denied|flatbuffers.*failed|BUILD_FAILED") {
            $bt = Join-Path $vcpkgRoot "buildtrees\flatbuffers"
            if (Test-Path $bt) {
                Write-Host "Removing stalled flatbuffers build tree and retrying once..."
                Remove-Item -Path $bt -Recurse -Force -ErrorAction SilentlyContinue
                & $vcpkgExe install $pkg 2>&1 | Tee-Object -Variable vcpkgOut2 | Out-Host
                if ($LASTEXITCODE -eq 0) { $installed = $true; break }
            }
        }
    }
    if (-not $installed) {
        Write-Host ""
        Write-Host "If you saw 'Access is denied' on flatbuffers: close File Explorer/IDE from this project, or move the project to C:\dev\Iris-art-app and run again."
        Write-Error "vcpkg install opencv4 failed. Ensure Visual Studio C++ tools and Git are installed."
    }
    $ocvDir = Get-OpenCVDirFromVcpkg $vcpkgRoot
}
if (-not $ocvDir) {
    Write-Error "OpenCV not found under vcpkg. Check vcpkg list opencv4."
}

$env:OpenCV_DIR = $ocvDir
Write-Host "OpenCV_DIR set to: $ocvDir"
Add-VcpkgBinToPath $ocvDir

# 4) Clean, build, copy vcpkg DLLs next to exe, then run
# Build first so runner dir exists; then copy so iris_engine.dll can load OpenCV at runtime.
Set-Location $ProjectRoot
Clear-BuildWindows $ProjectRoot | Out-Null
flutter clean
flutter pub get
flutter build windows --debug
Copy-VcpkgDllsToRunner -openCvDir $ocvDir -root $ProjectRoot
flutter run -d windows
