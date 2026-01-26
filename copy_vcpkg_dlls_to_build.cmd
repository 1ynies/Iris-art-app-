@echo off
title Copy OpenCV DLLs to build
setlocal
cd /d "%~dp0"
echo.
echo Copying vcpkg/OpenCV DLLs so iris_engine.dll can load...
echo.
set "VCPKG_BIN=%~dp0.vcpkg\installed\x64-windows\bin"
set "DEST_DEBUG=%~dp0build\windows\x64\runner\Debug"
set "DEST_RELEASE=%~dp0build\windows\x64\runner\Release"
if not exist "%VCPKG_BIN%" (
    echo ERROR: .vcpkg\installed\x64-windows\bin not found.
    echo Run build_with_opencv.cmd from a CMD or PowerShell window first.
    echo.
    pause
    exit /b 1
)
set COPIED=0
if exist "%DEST_DEBUG%" (
    xcopy /Y /Q "%VCPKG_BIN%\*.dll" "%DEST_DEBUG%\" >nul
    echo Copied vcpkg DLLs to build\windows\x64\runner\Debug
    set COPIED=1
)
if exist "%DEST_RELEASE%" (
    xcopy /Y /Q "%VCPKG_BIN%\*.dll" "%DEST_RELEASE%\" >nul
    echo Copied vcpkg DLLs to build\windows\x64\runner\Release
    set COPIED=1
)
if %COPIED%==0 (
    echo ERROR: No build\windows\x64\runner\Debug or Release folder.
    echo Build the app first \(e.g. flutter build windows --debug\).
    echo.
    pause
    exit /b 1
)
echo.
echo Done. Run the app or "flutter run -d windows" again.
echo.
pause
exit /b 0
