@echo off
setlocal
cd /d "%~dp0"
REM Put vcpkg OpenCV DLLs on PATH so iris_engine.dll finds them, then run the app.
set VCPKG_BIN=%~dp0.vcpkg\installed\x64-windows\bin
set EXE=%~dp0build\windows\x64\runner\Debug\iris_designer.exe
if not exist "%EXE%" (
    echo "%EXE%" not found. Build the app first (e.g. run build_with_opencv.cmd).
    pause
    exit /b 1
)
set "PATH=%VCPKG_BIN%;%PATH%"
start "" "%EXE%"
exit /b 0
