# Iris Designer

![Iris Designer Logo](assets/Images/appicon.png)

A sophisticated Flutter application that transforms iris images into stunning artistic creations. Leveraging advanced image processing techniques, Iris Designer allows users to extract, edit, and compose iris-based artwork with professional-grade tools.

**Windows only** — built around the Iris Engine native DLL and OpenCV on Windows. Linux and macOS are not supported.

## 🌟 Overview

Iris Designer is a Windows desktop application designed for artists and enthusiasts who want to create unique art pieces from iris photographs. The app combines computer vision (OpenCV) with intuitive design tools to provide a seamless workflow from image upload to final artwork generation.

### Key Highlights
- **Advanced Iris Detection**: Utilizes OpenCV-powered algorithms for precise iris extraction
- **Multi-Step Editing Pipeline**: Professional-grade editing tools for circling, flash correction, and color adjustment
- **Flexible Art Composition**: Support for 1-6 iris images with various layouts and effects
- **Client Management**: Built-in session management for professional artist-client workflows
- **Windows native**: Iris Engine DLL + OpenCV; no Linux/macOS support

## ✨ Features

### 🎨 Client Onboarding
- **Intake Form**: Collect client information including name, email, and country
- **Session Management**: Persistent client sessions with Hive local storage
- **Professional Workflow**: Designed for artist-client interactions

### 📸 Image Management
- **Bulk Upload**: Support for uploading up to 6 iris images per session
- **File Picker Integration**: Seamless image selection from device storage
- **Project Organization**: Structured project management with image tracking

### 🔧 Advanced Editor
- **Circling Tool**: Precise iris selection with adjustable outer/inner radii
- **Shape Control**: Oval ratio adjustment for non-circular irises
- **Positioning**: Fine-tune iris placement with offset controls
- **Flash Correction**: Automatic flash artifact removal and intensity adjustment
- **Color Adjustment**: Professional color grading tools for artistic enhancement

### 🎭 Art Studio
- **Multi-Image Layouts**: Support for compositions with 1-6 iris images
- **Effect Library**:
  - **Solo Effects**: Pure, Halo, Dust, Sun, Explosion
  - **Duo Effects**: Eternishape, Fusion, Love, Equilibrium
- **Flexible Sizing**: Multiple predefined sizes and custom dimensions
- **Alignment Options**: Row, Column, Square, and Rectangle layouts
- **Real-time Preview**: Instant visual feedback for all adjustments

### 🛠 Technical Features
- **State Management**: BLoC pattern for predictable state handling
- **Routing**: Go Router for seamless navigation
- **Image Processing**: OpenCV integration for computer vision tasks
- **Local Storage**: Hive database for offline session persistence
- **UI Components**: Custom widgets with Material Design principles

## 🛠 Tech Stack

### Core Framework
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language

### State Management & Architecture
- **BLoC**: Business Logic Component pattern
- **Clean Architecture**: Domain-Driven Design principles
- **Dependency Injection**: GetIt service locator

### Image Processing
- **Iris Engine (C++/FFI)**: Native processing via `iris_engine.dll`
- **OpenCV**: Computer vision algorithms (Hough circles, inpaint)
- **Image Package**: Core image manipulation
- **Path Provider**: File system access

### UI & Design
- **Google Fonts**: Typography (Poppins)
- **Flutter SVG**: Vector graphics support
- **Material Design**: Consistent design system
- **Custom Themes**: Dark theme optimized for creative work

### Storage & Persistence
- **Hive**: Lightweight NoSQL database
- **Shared Preferences**: Simple key-value storage

### Navigation & Routing
- **Go Router**: Declarative routing
- **Deep Linking**: URL-based navigation support

### Development Tools
- **Flutter Lints**: Code quality enforcement
- **Build Runner**: Code generation
- **Mocktail**: Testing utilities

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.4 or higher)
- Dart SDK (included with Flutter)
- Visual Studio 2022 with Desktop C++ workload
- OpenCV (via vcpkg or a local OpenCV build)

### Installation (Windows)

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/iris-designer.git
   cd iris-designer
   ```

2. **Install Dart dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter pub run build_runner build
   ```

4. **Build & run (recommended)**
   ```bash
   build_with_opencv.cmd
   ```

   This script installs OpenCV via vcpkg (first run), builds the native DLL,
   and runs the app.

5. **Run the application (manual)**
   ```bash
   flutter run -d windows
   ```

### OpenCV + DLLs (Windows)
- The build copies `iris_engine.dll` and OpenCV runtime DLLs next to the exe
  (POST_BUILD in `windows/runner/CMakeLists.txt`).
- `DynamicLibrary.open('iris_engine.dll')` relies on the DLL being next to the exe.

## 📖 Usage

### Creating a New Project

1. **Launch the App**: Start with the splash screen
2. **Client Intake**: Fill in client details (name, email, country)
3. **Image Upload**: Select and upload iris images (max 6 per session)
4. **Edit Images**: Process each image through the three editing steps:
   - **Circling**: Define iris boundaries
   - **Flash Correction**: Remove unwanted lighting artifacts
   - **Color Adjustment**: Fine-tune color balance
5. **Art Creation**: Move to Art Studio for composition
6. **Export**: Generate final artwork

### Editing Workflow

#### Circling Step
- Adjust outer radius to encompass the entire iris
- Set inner radius to exclude the pupil
- Modify oval ratio for non-circular irises
- Position the selection using offset controls

#### Flash Correction
- Automatic detection of flash reflections
- Manual intensity adjustment
- Preview changes in real-time

#### Color Adjustment
- RGB channel controls
- Saturation and brightness sliders
- Professional color grading tools

### Art Studio Composition

#### Layout Selection
- Choose from 1-6 iris layouts
- Select alignment (Row, Column, Square, Rectangle)

#### Effect Application
- Browse solo effects for individual irises
- Apply duo effects for paired compositions
- Preview effects instantly

#### Sizing and Export
- Select from predefined sizes
- Custom dimension support
- Export to various formats

## 🏗 Project Structure

```
lib/
├── Core/
│   ├── Config/
│   │   ├── App_router.dart          # Navigation configuration
│   │   ├── dependency_injection.dart # DI setup
│   │   ├── hive_init.dart           # Database initialization
│   │   └── Theme.dart               # App theming
│   ├── Services/                    # Core services
│   ├── Shared/
│   │   └── Widgets/                 # Reusable UI components
│   └── Utils/                       # Utility functions
├── Features/
│   ├── ONBOARDING/                  # Client intake feature
│   │   ├── Domain/
│   │   ├── Presentation/
│   │   └── Data/
│   ├── PROJECT_HUB/                 # Image management
│   │   ├── Domain/
│   │   ├── Presentation/
│   │   └── Data/
│   ├── EDITOR/                      # Image editing tools
│   │   ├── Domain/
│   │   ├── Presentation/
│   │   └── Data/
│   └── ART_STUDIO/                  # Art composition
│       ├── Domain/
│       ├── Presentation/
│       └── Data/
└── main.dart                       # App entry point
```

## 🤝 Contributing

We welcome contributions to Iris Designer! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Write comprehensive tests
- Update documentation for new features
- Target Windows only (native DLL + OpenCV)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- OpenCV community for computer vision algorithms
- Flutter team for the amazing framework
- Material Design for design inspiration
- All contributors and users of Iris Designer

## 📞 Contact

For questions, suggestions, or collaborations:
- **Email**: your.email@example.com
- **GitHub**: [yourusername](https://github.com/yourusername)
- **LinkedIn**: [Your LinkedIn](https://linkedin.com/in/yourprofile)

---

*Transforming irises into art, one pixel at a time.*
# Iris-art-app-
