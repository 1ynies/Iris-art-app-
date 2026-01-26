# Copy vcpkg/OpenCV DLLs next to the exe so iris_engine.dll can load (fixes error 126).
# Run from PowerShell in the project folder: .\copy_vcpkg_dlls_to_build.ps1
$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$vcpkgBin = Join-Path $root ".vcpkg\installed\x64-windows\bin"
$destDebug = Join-Path $root "build\windows\x64\runner\Debug"
$destRelease = Join-Path $root "build\windows\x64\runner\Release"

if (-not (Test-Path $vcpkgBin -PathType Container)) {
    Write-Host "ERROR: .vcpkg\installed\x64-windows\bin not found. Run build_with_opencv first." -ForegroundColor Red
    exit 1
}
$copied = 0
if (Test-Path $destDebug -PathType Container) {
    Copy-Item -Path (Join-Path $vcpkgBin "*.dll") -Destination $destDebug -Force
    Write-Host "Copied vcpkg DLLs to build\windows\x64\runner\Debug"
    $copied++
}
if (Test-Path $destRelease -PathType Container) {
    Copy-Item -Path (Join-Path $vcpkgBin "*.dll") -Destination $destRelease -Force
    Write-Host "Copied vcpkg DLLs to build\windows\x64\runner\Release"
    $copied++
}
if ($copied -eq 0) {
    Write-Host "ERROR: No build\windows\x64\runner\Debug or Release folder. Build the app first." -ForegroundColor Red
    exit 1
}
Write-Host "Done. Run the app or 'flutter run -d windows' again."
