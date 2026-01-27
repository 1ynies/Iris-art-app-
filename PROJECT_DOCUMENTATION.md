# Iris Designer — Full Project Documentation

## App Summary
Iris Designer is a Windows-only Flutter desktop application that transforms iris photographs into artistic compositions. The UI is built in Flutter/Dart with a clean-architecture feature layout and BLoC state management. The core image processing is performed by a native C++ "Iris Engine" DLL (OpenCV-backed) accessed via Dart FFI. The workflow takes a client from intake → image upload → multi-step iris editing → art composition → preview/export.

## Tech Stack
### Core
- Flutter (Windows desktop)
- Dart (SDK ^3.10.4)
- Material Design + Google Fonts

### State Management & Architecture
- BLoC (feature-level state)
- Clean Architecture (Domain/Data/Presentation)
- GetIt (dependency injection)
- Equatable (value equality)

### Native Image Processing
- C++20 DLL (`iris_engine.dll`)
- OpenCV (Hough circles, inpainting, color ops)
- Dart FFI bindings (raw RGBA buffers)

### Storage
- Hive (client sessions and image paths)

### UI & Media
- flutter_svg (SVG icons)
- file_picker / desktop_drop (image input)
- flutter_inappwebview (Photopea integration)

### Tooling
- CMake (Windows build)
- vcpkg (OpenCV install)
- PowerShell/CMD build helpers

## Architecture Overview
- `lib/Core`: Shared app configuration, native bindings, services, widgets, utilities.
- `lib/Features`: Feature modules (ONBOARDING, PROJECT_HUB, EDITOR, ART_STUDIO) with Data/Domain/Presentation layers.
- `windows/iris_engine`: Native C++ code compiled into `iris_engine.dll` and copied next to the executable.
- `windows/runner`: Flutter Windows host executable and build wiring.

## User Flow (Detailed)
1. **Splash Screen**
   - Animated logo for ~3 seconds.
   - Automatically routes to intake screen.
2. **Client Intake**
   - Collects client name, email, country.
   - Validates inputs and supports session resume (24h window).
   - Shows a session history dialog to resume active sessions.
3. **Image Prep (Screen 1)**
   - Upload/drag up to 6 iris images (JPG/PNG/JPEG).
   - Enforces max count, detects duplicates, and shows toasts.
   - Persisted to Hive as raw imported photos.
4. **Editor (Iris Editing)**
   - Queue-based editing for each image.
   - Step 1: Circling (manual outer/inner iris selection).
   - Step 2: Flash correction (native OpenCV inpaint).
   - Step 3: Color adjustment (native vibrance/gamma/clarity).
   - Supports skipping steps, resetting selection, and removing images from queue.
5. **Image Prep (Screen 2 / Workspace)**
   - Shows edited images only (generated art list).
   - Drag edited images into workspace grid.
6. **Art Studio**
   - Choose effects and layouts based on number of images.
   - Configure sizes and layout alignment.
   - Generate preview via Photopea tab and export/download.

## Features (Each Feature in Detail)

### 1) Client Intake & Session Management
- Two-panel onboarding screen: promotional panel + form panel.
- Inputs: client name, email, country (with country picker).
- Auto-capitalization of name.
- Session resume detection: checks Hive for matching name/email/country.
- Session history dialog (24-hour active sessions) with:
  - Client details
  - Uploaded image counts
  - Generated artwork counts
  - Time until expiry
  - One-click resume

### 2) Image Upload & Project Hub
- Drag-and-drop support for the entire window.
- File picker supports multiple image selection.
- Upload limits:
  - Max 6 images total
  - Rejects invalid extensions
  - Avoids duplicates
- Stores image paths in Hive for session persistence.
- Hover-to-delete UI in the grid.
- “Continue” button pushes images to the editor.

### 3) Iris Editor (Step-by-Step)
**Workflow**
- A queue shows all images and their per-step status (Pending / Done / Editing).
- The editor enforces step order: Circling → Flash Correction → Color Adjustment.
- Each step can be skipped (flash/color), and selections can be reset.

**Circling (Step 0)**
- Interactive overlay with two circles: outer iris and inner pupil.
- Supports:
  - Dragging the outer circle (iris)
  - Dragging the inner circle (pupil)
  - Resizing both via edge hit targets
  - Oval ratio adjustment (ellipse vs circle)
- When “Cut & Apply” is pressed:
  - Uses native cut-and-warp if available (FFI to `iris_engine_process_iris_cut_from_view`)
  - Falls back to auto-detection (Hough circles) if cut-and-warp not available

**Flash Correction (Step 1)**
- Native OpenCV inpainting through `iris_engine_remove_flash`.
- Brush UI exists but is disabled in this screen (engine-only workflow).
- Threshold and dilation are fixed in the call for now.

**Color Adjustment (Step 2)**
- Sliders: brightness, contrast, saturation, vibrance.
- Live preview uses a color matrix for instant UI feedback.
- Presets (blue, green, brown, hazel, black, grey) map to recommended parameter boosts.
- Final “Apply Changes” runs native effects in the Iris Engine.

**Queue Management**
- Add new images via file picker (JPG/PNG).
- Remove images from queue (must keep at least one).
- Progress and edits are saved to Hive when navigating back.

### 3.1) Editor Help & Guidance
- The global navbar exposes per-screen help dialogs with step-by-step hints.
- Editor help specifically guides Circling → Flash → Color workflow.

### 4) Art Studio (Composition & Effects)
**Studio Tab**
- Solo effects list (Pure, Halo, Dust, Sun, Explosion).
- Duo effects list (Fusion, Collision, Balance, Binary, Eclipse) when two images are used.
- Size selection with derived alignment (Row/Column/Square/Round/Rectangle).
- Layout preview by number of images:
  - Case 1: single iris on canvas
  - Case 2: two iris diagonal layout + duo effects selector
  - Case 3–6: placeholder compositions for 3–6 images (future expansion)

**Preview & Print Tab**
- Uses embedded Photopea (web-based editor) via `flutter_inappwebview`.
- Inputs are base64 images passed to Photopea.
- Provides “Edit Manually” and “Download / Print” actions.

### 5) Photopea Integration (Web Tooling)
- WebView-based engine for external editing and export.
- Dedicated service handles:
  - Uploading images to Photopea
  - Running scripts for circling, flash fix, color adjustment
  - Exporting PNG via `saveToOE`
- Current editor screen uses native engine; Photopea remains available for Studio previews and optional flows.

### 6) Build & Deployment Tools
- `build_with_opencv.cmd/.ps1`: clones vcpkg (if needed), installs OpenCV, builds app + DLL, runs app.
- `copy_vcpkg_dlls_to_build.cmd/.ps1`: copies OpenCV runtime DLLs to build output.
- `run_iris_designer.cmd`: launches the built executable with OpenCV DLLs in PATH.
- `clean_windows_build.ps1`: removes `build/windows` to resolve CMake/OpenCV cache issues.

### 7) Navigation & Routing
- GoRouter routes:
  - `/` → Splash
  - `/intake` → Client intake
  - `/image-prep` → Image upload hub
  - `/image-prep-2` → Workspace
  - `/editor` → Iris editor
  - `/art-studio` → Art studio
- Redirect guard forces `/image-prep` to `/intake` if no session data is passed.
- Global error page handles unknown routes.

## Data Model & Persistence
### ClientSession (Hive)
- `id`, `clientName`, `email`, `country`
- `importedPhotos`: raw uploads
- `generatedArt`: edited/processed output paths
- `createdAt`: used for 24h expiry and session cleanup

### ProjectDetails
- `projectId`, `clientName`, `imageUrls`
- Used by Project Hub state

### IrisImage
- `imagePath` (current version)
- `originalPath` (raw, for rollback)
- step flags: `isCirclingDone`, `isFlashDone`, `isColorDone`

## Native Code (Detailed)
### DLL / Engine Overview
- **Name:** `iris_engine.dll`
- **Purpose:** high-performance iris detection and editing pipeline
- **Phases:**
  - Phase 1: Cut-and-warp (user-defined circles, radial stretch)
  - Phase 2: Auto-detect iris/pupil (Hough Circles)
  - Phase 3: Flash removal (threshold + dilate + OpenCV inpaint)
  - Phase 4: Color effects (vibrance, gamma, sharpness, clarity)
  - Phase 5: Export (stubbed, not implemented)

### Core Algorithms
- Hough circle detection for iris/pupil
- Inpainting for flash artifacts
- LAB color operations + CLAHE for clarity
- Radial stretch for pupil shrink in cut-and-warp

### Dart FFI Layers
- `IrisEngineBindings`: raw RGBA load/get + cut/flash/effects.
- `NativeIrisBridge`: cut-and-warp bridge using view-space parameters.
- Loader resolves DLL by filename only so it must be next to the executable.

### Native Build Notes
- OpenCV is required at configure time (`find_package(OpenCV REQUIRED)`).
- vcpkg support is wired in the CMake files for automatic DLL copying.
- The app runs only if:
  - `iris_engine.dll` is built
  - OpenCV runtime DLLs are next to the exe or on PATH

## What’s Working
- Windows-only launch guard and UI runs correctly on Windows.
- Hive-based sessions (create, resume, 24h cleanup).
- Image upload with limits, drag-and-drop, and persistence.
- Iris editor pipeline for:
  - Circling (manual + native cut-and-warp)
  - Flash removal (OpenCV inpaint)
  - Color effects (native pipeline)
- Art Studio UI:
  - Solo and duo effect selection
  - Size/alignment selection
  - Preview tab with Photopea
- Native DLL build pipeline with CMake + vcpkg scripts.

## What’s Not Working or Incomplete
- **Export pipeline in native C++**: `export_to_file` returns `false` (not implemented).
- **Backend integration**: ProjectHub repository is mock (fake upload URL).
- **Tests**: only default Flutter counter test exists (not aligned with app).
- **Art Studio cases 3–6**: placeholders only; no real compositing logic.
- **Photopea vs native editor split**: Photopea editor logic exists but main editor uses native engine only.
- **Assets for flutter_launcher_icons**: `assets/icon.png` referenced but not present in repo.
- **Unused/placeholder Dart files**: `custom_text_field.dart`, `dotted_button_widget.dart`, `Consts.dart` contain no active code.
- **Potential missing asset**: `assets/Icons/arrow_right.svg` is referenced in intake but not present in assets list.
- **Empty file**: `PhotopeaPreviewTab.dart` exists but contains no implementation.
- **Fallback color adjuster**: `color_adjustment_dart.dart` is a Dart fallback but is not invoked in the main editor flow.

## Project Structure (Every File with Description)
```
/ (repo root)
  .gitignore — Git ignore rules for the repository
  .metadata — Flutter project metadata
  analysis_options.yaml — Flutter/Dart lint configuration
  build_with_opencv.cmd — CMD wrapper for OpenCV build/run script
  build_with_opencv.ps1 — PowerShell build script (vcpkg + OpenCV + build)
  clean_windows_build.ps1 — Cleans Windows build folder
  copy_vcpkg_dlls_to_build.cmd — Copies OpenCV DLLs to build output (CMD)
  copy_vcpkg_dlls_to_build.ps1 — Copies OpenCV DLLs to build output (PowerShell)
  HOW_TO_FIX_IRIS_ENGINE.txt — Troubleshooting native DLL load issues
  pubspec.yaml — Flutter app manifest and dependencies
  pubspec.lock — Locked dependency versions
  README.md — Project overview and basic usage
  RUN_DEBUG_WINDOWS.md — Debug/run instructions for Windows
  run_iris_designer.cmd — Launch built Windows executable with OpenCV DLLs

  .vs/
    CMakeWorkspaceSettings.json — Visual Studio CMake workspace settings
    ProjectSettings.json — Visual Studio project settings
    VSWorkspaceState.json — Visual Studio workspace state
    slnx.sqlite — Visual Studio solution cache
    Iris-art-app-.slnx/
      FileContentIndex/
        bc47c6d2-44b6-4195-8d62-f695266e1e50.vsidx — VS file content index
      v18/
        .wsuo — Visual Studio user options
        Browse.VC.db — Visual Studio browse database
        DocumentLayout.json — Visual Studio layout state

  assets/
    Icons/
      arrow_up_tray.svg — Upload/drag icon
      brush.svg — Art creation icon
      chevron.svg — Navigation / continue icon
      color_swatch_solid.svg — Color adjustment step icon
      envelope-solid.svg — Email field icon
      eye_solid.svg — Eye/iris icon
      flash_solid.svg — Flash correction icon
      globe-solid.svg — Location/country icon
      photo.svg — Studio preview icon
      sparkles_solid.svg — Effects icon
      user-mini.svg — User/client icon
      view_finder_solid.svg — Circling step icon
    Images/
      appicon.png — App icon used in splash/onboarding
      high-resolution-anatomy-human-eye-highlighting-iris-vasculature_607202-22001-2727869561.jpg — Promo image for onboarding
      maxresdefault-2904691564.jpg — Additional promo/sample image
    psd-files/
      Solo Square 20 cm x 20 cm.psd — PSD template for art output

  lib/
    main.dart — App entry point, Windows-only guard, DI + Hive init
    sizes.txt — Reference list of supported print sizes

    Core/
      Config/
        App_router.dart — GoRouter config and navigation guards
        Consts.dart — Empty placeholder for constants
        dependecy_injection.dart — GetIt registrations for features
        failures.dart — Failure abstractions for domain layer
        hive_init.dart — Hive initialization helper
        Theme.dart — App color palette and text styles
      Native/
        iris_engine_loader.dart — Loads `iris_engine.dll` by name
        native_iris_bridge.dart — FFI bridge for cut-and-warp (Phase 1)
      Services/
        hive_service.dart — Session persistence + 24h cleanup
        iris_engine_bindings.dart — FFI bindings for engine phases 2–4
        iris_engine_service.dart — High-level native processing API (file in/out)
        photopea_service.dart — Photopea WebView automation + export
      Shared/
        Widgets/
          global_custom_navbar.dart — AppBar with contextual help dialogs
          global_submit_button_widget.dart — Primary CTA button widget
      Utils/
        toast_service.dart — Success/error toast helper

    Features/
      ONBOARDING/
        Data/
          repositories/
            onboarding_repository_impl.dart — Creates Hive-backed sessions
        Domain/
          entities/
            client_session.dart — Hive model for client session
            client_session.g.dart — Generated Hive adapter
          respositories/
            onboarding_repository.dart — Onboarding repository contract
          usecases/
            start_session_usecase.dart — Start session use case
        Presentation/
          bloc/
            onboarding_bloc.dart — Intake form state management
          pages/
            client_intake_screen.dart — Two-panel intake screen
            splash_screen.dart — Animated splash
            views/
              intake_screen_first_half.dart — Promotional panel content
              intake_screen_second_half.dart — Intake form and resume logic
          widgets/
            custom_dropdown.dart — Country picker dropdown
            custom_text_field.dart — Unused legacy input widget
            session-history-dialog.dart — Session history/resume dialog
            text_field_widget.dart — Styled text input field

      PROJECT_HUB/
        Data/
          repositories/
            project_hub_repository_impl.dart — Mock project data & upload
        Domain/
          entities/
            project_details.dart — Project details model
          respositories/
            project_hub_repository.dart — Project hub repository contract
          usecases/
            load_project_data_usecase.dart — Load project data
            upload_image_usecase.dart — Upload image (mocked)
        Presentation/
          bloc/
            project_hub_bloc.dart — Upload, remove, and load logic
          pages/
            screen 1/
              image_prep_screen1.dart — Upload screen
              views/
                image_prep_view1.dart — Upload grid + drop zone
                instruction_view.dart — Guidance panel
            screen 2/
              image_prep_screen2.dart — Workspace split view
              views/
                image_editing_view.dart — Drop zone and art studio navigation
                image_prep_view2.dart — Edited image gallery with drag
          widgets/
            client_info_card.dart — Client summary card
            dotted_button_widget.dart — Unused dotted upload button
            image_grid_widget.dart — Image grid with hover delete
            status_chip_widget.dart — Status chip (ACTIVE SESSION)

      EDITOR/
        Domain/
          entities/
            circling_params.dart — Circling view parameters
            iris_image.dart — Image model with step metadata
          services/
            color_adjustment_dart.dart — Dart-only color adjustment (fallback)
          usecases/
            save_image_progress_usecase.dart — Mock save progress use case
        Presentation/
          bloc/
            editor_bloc.dart — Photopea-based editing events (unused in screen)
            editor_event.dart — Editor event definitions
            editor_state.dart — Editor state model
          pages/
            iris_editing_screen.dart — Main editor workflow screen
          views/
            circling_view.dart — Interactive iris/pupil selection UI
            color_adjustment_view.dart — Sliders + presets + preview
            flash_correction_view.dart — Flash correction view (brush optional)
          widgets/
            queue_image_item.dart — Queue tile with status badge

      ART_STUDIO/
        Presentation/
          pages/
            iris_studio_screen.dart — Studio + Photopea preview tabs
            PhotopeaPreviewTab.dart — Empty placeholder file (no implementation)
          views/
            case1_view.dart — 1-iris layout
            case2_view.dart — 2-iris layout + duo effects
            case3_view.dart — 3-iris placeholder layout
            case4_view.dart — 4-iris placeholder layout
            case5_view.dart — 5-iris placeholder layout
            case6_view.dart — 6-iris placeholder layout
          widgets/
            iris_placeholder.dart — Circular iris placeholder widget

  test/
    widget_test.dart — Default Flutter counter test

  windows/
    .gitignore — Windows build artifact ignore rules
    CMakeLists.txt — Top-level Windows build configuration
    flutter/
      CMakeLists.txt — Flutter-managed build rules
      generated_plugin_registrant.cc — Generated plugin registration
      generated_plugin_registrant.h — Generated plugin registration header
      generated_plugins.cmake — Generated plugin CMake glue
    iris_engine/
      CMakeLists.txt — Native DLL build config with OpenCV
      iris_cut.cpp — Phase 1 cut-and-warp implementation
      iris_cut.h — Cut-and-warp declarations
      iris_engine.cpp — Core image processing (Hough/inpaint/effects)
      iris_engine.h — Native C++ API definitions
      iris_engine_ffi.cpp — C API wrapper for FFI
      iris_engine_ffi.h — C API header for FFI
      README.md — Native engine build/usage notes
    runner/
      CMakeLists.txt — Windows runner build + DLL copy logic
      copy_vcpkg_dlls.cmake — CMake script to copy OpenCV DLLs
      flutter_window.cpp — Flutter window integration
      flutter_window.h — Flutter window header
      main.cpp — Windows entry point for Flutter
      resource.h — Windows resource IDs
      runner.exe.manifest — Windows app manifest
      Runner.rc — Windows resources
      utils.cpp — Win32 utility helpers
      utils.h — Win32 utility headers
      win32_window.cpp — Win32 window implementation
      win32_window.h — Win32 window header
      resources/
        app_icon.ico — Windows app icon
```
