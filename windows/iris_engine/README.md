# Iris Engine — Native C++ DLL (2026)

Flutter handles the UI; this engine handles image processing via **Dart FFI** and **OpenCV** (required for circling).

## What you need for circling to work

1. **Run on Windows** with `iris_engine.dll` next to the app executable.
2. **Build the DLL with OpenCV** — in `windows/iris_engine/CMakeLists.txt`, `find_package(OpenCV REQUIRED)` enforces OpenCV at configure time.

### Building with OpenCV

**Quick fix (recommended)** — from the **project root** (requires Git + Visual Studio C++ tools, and internet on first run):

- **From Command Prompt (cmd):** run `build_with_opencv.cmd` (or double‑click it in Explorer).
- **From PowerShell:** run  
  `powershell -ExecutionPolicy Bypass -File .\build_with_opencv.ps1`  
  Do **not** paste the contents of the `.cmd` file into PowerShell (you’ll get “Missing '(' after 'if'” / “splatting operator” errors).

This will clone vcpkg into `.vcpkg` if needed, install OpenCV, set `OpenCV_DIR`, clear the Windows build, then run `flutter clean`, `flutter pub get`, and `flutter run -d windows`. First run can take 10–30 minutes. If vcpkg fails with **"Access is denied"** on flatbuffers, close File Explorer and your IDE from the project folder and run the script again, or move the project to a short path (e.g. `C:\dev\Iris-art-app`) and run from there.

**Manual options:**

1. Install [OpenCV for Windows](https://opencv.org/releases/) and note the path to the **build** folder (e.g. `C:/opencv/build`), or use vcpkg: `vcpkg install opencv4:x64-windows` and set `OpenCV_DIR` to `%VCPKG_ROOT%\installed\x64-windows\share\opencv4`.
2. **Environment variable:**  
   ```powershell
   $env:OpenCV_DIR = "C:\opencv\build"   # or ...\installed\x64-windows\share\opencv4
   Remove-Item -Recurse -Force build\windows -ErrorAction SilentlyContinue
   flutter clean ; flutter pub get ; flutter run -d windows
   ```
3. **CMake cache:** when configuring, pass `-DOpenCV_DIR=C:/opencv/build`.

The build copies `iris_engine.dll` and OpenCV DLLs next to the Flutter app executable
via POST_BUILD in `windows/iris_engine/CMakeLists.txt`, so `DynamicLibrary.open('iris_engine.dll')`
resolves by filename only.

## Layout

| File | Role |
|------|------|
| `iris_engine.h` | C++ API: `IrisObject`, `CircleResult`, `EffectParams`, Phase 2–5 declarations |
| `iris_engine_ffi.h` | C API for Dart FFI (opaque handle, no C++ types) |
| `iris_engine.cpp` | Core logic (load/get RGBA; OpenCV Hough circles, inpaint, effects) |
| `iris_engine_ffi.cpp` | FFI wrappers |

## Editor integration

- **Circling (step 0):** Uses only `IrisEngineService.processCircling(path)` → OpenCV Hough circles in C++. No Dart fallback.
- **Flash (step 1):** `IrisEngineService.processFlashRemoval(path)` (OpenCV inpaint when available).
- **Color (step 2):** `IrisEngineService.processColorEffects(path, …)`.

If the engine DLL is missing or OpenCV was not linked at build time, circling fails with an error; the app does not fall back to Dart/image for circling.
