@echo off
title Iris Designer - Build with OpenCV
setlocal
cd /d "%~dp0"
echo.
echo === Iris Designer: building with OpenCV (this may take a while) ===
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_with_opencv.ps1"
set EXIT_CODE=%errorlevel%
echo.
if %EXIT_CODE% neq 0 (
    echo Build script exited with code %EXIT_CODE%. See above for details.
) else (
    echo Build and run finished.
)
echo.
pause
exit /b %EXIT_CODE%
