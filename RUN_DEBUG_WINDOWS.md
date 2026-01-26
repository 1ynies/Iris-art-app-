# Run Iris Designer in Debug Mode on Windows 10

Do everything from the **project folder**:  
`C:\Users\Hiba\Desktop\Iris-designer\Iris-art-app-`

---

## Option A: First time or full rebuild (recommended)

This installs OpenCV via vcpkg (if needed), builds the app, copies DLLs, and runs it.

1. **Open a terminal in the project folder**
   - In **Cursor**: `Terminal` → `New Terminal` (or press **Ctrl+`**)
   - Or open **PowerShell** or **CMD**, then:
     ```bat
     cd /d "C:\Users\Hiba\Desktop\Iris-designer\Iris-art-app-"
     ```

2. **Run the build script**
   - In **CMD**:
     ```bat
     build_with_opencv.cmd
     ```
   - In **PowerShell**:
     ```powershell
     .\build_with_opencv.ps1
     ```

3. Wait for the build to finish and the app to launch.  
   First run can take **10–30 minutes** if vcpkg is installing OpenCV.

---

## Option B: Already built — run in debug quickly

If you’ve run Option A at least once and only want to start the app in debug:

1. **Open a terminal in the project folder** (Cursor: **Ctrl+`**).

2. **Copy OpenCV DLLs** (needed for Iris Engine)
   - **PowerShell**:
     ```powershell
     .\copy_vcpkg_dlls_to_build.ps1
     ```
   - **CMD**:
     ```bat
     copy_vcpkg_dlls_to_build.cmd
     ```

3. **Run in debug**
   - **PowerShell**:
     ```powershell
     $env:PATH = "$PWD\.vcpkg\installed\x64-windows\bin;$env:PATH"
     flutter run -d windows
     ```
   - **CMD**:
     ```bat
     set "PATH=%CD%\.vcpkg\installed\x64-windows\bin;%PATH%"
     flutter run -d windows
     ```

---

## Option C: Debug from Cursor/VS Code (F5)

1. **Build and prepare DLLs at least once**  
   In the integrated terminal, run:
   ```powershell
   .\copy_vcpkg_dlls_to_build.ps1
   ```

2. **Set Windows as the run target**  
   - In the bottom-right status bar, click the **device** (e.g. “Chrome”)  
   - Choose **Windows**

3. **Start debugging**  
   - Press **F5** or use **Run** → **Start Debugging**

If you see **“Iris Engine not available”** when using Cut & Apply, run `.\copy_vcpkg_dlls_to_build.ps1` again from the project folder and then run (F5 or `flutter run -d windows`).

---

## Requirements

- **Windows 10** (64-bit)
- **Flutter** installed and on `PATH` (`flutter --version` works)
- **Visual Studio Build Tools** (or Visual Studio with “Desktop development with C++”)
- **Git** (for vcpkg when using the build script)

---

## Useful commands while the app is running

When you use `flutter run -d windows`:

- **r** = hot reload  
- **R** = hot restart  
- **q** = quit
