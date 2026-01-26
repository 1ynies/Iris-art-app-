# Run this when you see "generator platform does not match" or OpenCV/CMake cache errors on Windows.
# Then run: flutter run

$buildWindows = Join-Path $PSScriptRoot "build\windows"
if (Test-Path $buildWindows) {
    Remove-Item -Path $buildWindows -Recurse -Force
    Write-Host "Removed build\windows. Run 'flutter run' to rebuild."
} else {
    Write-Host "build\windows not found. Run 'flutter run'."
}
