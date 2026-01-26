// ignore_for_file: unused_element

/// Iris Engine — Dart FFI bindings to the native C++ DLL (2026).
///
/// Use [IrisEngineBindings.instance] to call the engine. On non-Windows
/// or if the DLL is missing, operations no-op or return null/false.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:iris_designer/Core/Native/iris_engine_loader.dart';

// -----------------------------------------------------------------------------
// FFI types (must match iris_engine_ffi.h)
// -----------------------------------------------------------------------------

typedef _GrayscaleNative = Int32 Function(
  Pointer<Uint8> rgba,
  Int32 width,
  Int32 height,
);
typedef _GrayscaleDart = int Function(
  Pointer<Uint8> rgba,
  int width,
  int height,
);

typedef _CreateNative = Pointer<Void> Function();
typedef _CreateDart = Pointer<Void> Function();

typedef _DestroyNative = Void Function(Pointer<Void> handle);
typedef _DestroyDart = void Function(Pointer<Void> handle);

typedef _LoadRgbaNative = Int32 Function(
  Pointer<Void> handle,
  Pointer<Uint8> rgba,
  Int32 width,
  Int32 height,
);
typedef _LoadRgbaDart = int Function(
  Pointer<Void> handle,
  Pointer<Uint8> rgba,
  int width,
  int height,
);

typedef _GetRgbaNative = Int32 Function(
  Pointer<Void> handle,
  Pointer<Uint8> outRgba,
  Int32 width,
  Int32 height,
);
typedef _GetRgbaDart = int Function(
  Pointer<Void> handle,
  Pointer<Uint8> outRgba,
  int width,
  int height,
);

typedef _CutIrisNative = Int32 Function(Pointer<Void> handle);
typedef _CutIrisDart = int Function(Pointer<Void> handle);

typedef _RemoveFlashNative = Int32 Function(
  Pointer<Void> handle,
  Float threshold,
  Int32 dilatePixels,
);
typedef _RemoveFlashDart = int Function(
  Pointer<Void> handle,
  double threshold,
  int dilatePixels,
);

typedef _ApplyEffectsNative = Int32 Function(
  Pointer<Void> handle,
  Float vibrance,
  Float gamma,
  Float sharpness,
  Float clarity,
);
typedef _ApplyEffectsDart = int Function(
  Pointer<Void> handle,
  double vibrance,
  double gamma,
  double sharpness,
  double clarity,
);

// -----------------------------------------------------------------------------
// Lazy-loaded DLL and symbols
// -----------------------------------------------------------------------------

DynamicLibrary? _loadEngine() {
  if (!Platform.isWindows) return null;
  return loadIrisEngine();
}

/// Iris Engine native bindings.
///
/// Step 1: [grayscaleInPlace] — in-place grayscale of RGBA bytes.
/// Later: load_rgba / get_rgba via handle for Phase 2–5.
class IrisEngineBindings {
  IrisEngineBindings._();

  static IrisEngineBindings? _instance;
  static IrisEngineBindings get instance {
    _instance ??= IrisEngineBindings._();
    return _instance!;
  }

  DynamicLibrary? _lib;
  bool _inited = false;

  void _ensureInit() {
    if (_inited) return;
    _inited = true;
    _lib = _loadEngine();
  }

  bool get isAvailable {
    _ensureInit();
    return _lib != null;
  }

  _GrayscaleDart? get _grayscale {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_GrayscaleNative>>('iris_engine_grayscale')
        .asFunction<_GrayscaleDart>();
  }

  _CreateDart? get _create {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_CreateNative>>('iris_engine_create')
        .asFunction<_CreateDart>();
  }

  _DestroyDart? get _destroy {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_DestroyNative>>('iris_engine_destroy')
        .asFunction<_DestroyDart>();
  }

  _LoadRgbaDart? get _loadRgba {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_LoadRgbaNative>>('iris_engine_load_rgba')
        .asFunction<_LoadRgbaDart>();
  }

  _GetRgbaDart? get _getRgba {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_GetRgbaNative>>('iris_engine_get_rgba')
        .asFunction<_GetRgbaDart>();
  }

  _CutIrisDart? get _cutIris {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_CutIrisNative>>('iris_engine_cut_iris')
        .asFunction<_CutIrisDart>();
  }

  _RemoveFlashDart? get _removeFlash {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_RemoveFlashNative>>('iris_engine_remove_flash')
        .asFunction<_RemoveFlashDart>();
  }

  _ApplyEffectsDart? get _applyEffects {
    _ensureInit();
    if (_lib == null) return null;
    return _lib!
        .lookup<NativeFunction<_ApplyEffectsNative>>('iris_engine_apply_effects')
        .asFunction<_ApplyEffectsDart>();
  }

  /// In-place grayscale of RGBA bytes (row-major, width * height * 4).
  /// Returns true if the engine ran successfully; false if unavailable or error.
  bool grayscaleInPlace(Uint8List rgba, int width, int height) {
    final fn = _grayscale;
    if (fn == null || rgba.length < width * height * 4) return false;
    return using((Arena arena) {
      final p = arena.allocate(rgba.length).cast<Uint8>();
      for (int i = 0; i < rgba.length; i++) {
        p[i] = rgba[i];
      }
      final r = fn(p, width, height);
      if (r != 0) {
        for (int i = 0; i < rgba.length; i++) {
          rgba[i] = p[i];
        }
      }
      return r != 0;
    });
  }

  /// Optional: create an engine handle for future load_rgba / get_rgba / effects.
  Pointer<Void>? createHandle() => _create?.call();

  void destroyHandle(Pointer<Void>? handle) {
    if (handle != null && handle != nullptr) _destroy?.call(handle);
  }

  /// Load RGBA into the engine object. Returns true on success.
  bool loadRgba(Pointer<Void> handle, Uint8List rgba, int width, int height) {
    final fn = _loadRgba;
    if (fn == null || rgba.length < width * height * 4) return false;
    return using((Arena arena) {
      final p = arena.allocate(rgba.length).cast<Uint8>();
      for (int i = 0; i < rgba.length; i++) p[i] = rgba[i];
      return fn(handle, p, width, height) != 0;
    });
  }

  /// Write current image from the engine into [outRgba]. Returns true on success.
  bool getRgba(Pointer<Void> handle, Uint8List outRgba, int width, int height) {
    final fn = _getRgba;
    if (fn == null || outRgba.length < width * height * 4) return false;
    return using((Arena arena) {
      final p = arena.allocate(outRgba.length).cast<Uint8>();
      if (fn(handle, p, width, height) == 0) return false;
      for (int i = 0; i < outRgba.length; i++) outRgba[i] = p[i];
      return true;
    });
  }

  /// Phase 2: Detect + cut iris (alpha outside iris = 0). Returns true on success.
  bool cutIris(Pointer<Void> handle) {
    final fn = _cutIris;
    if (fn == null) return false;
    return fn(handle) != 0;
  }

  /// Phase 3: Remove flash (threshold 0..1, dilate 2–3). Returns true on success.
  bool removeFlash(Pointer<Void> handle, {double threshold = 0.95, int dilatePixels = 3}) {
    final fn = _removeFlash;
    if (fn == null) return false;
    return fn(handle, threshold, dilatePixels) != 0;
  }

  /// Phase 4: Apply effects. gamma/vibrance ~1 = no change; sharpness/clarity 0..4.
  bool applyEffects(Pointer<Void> handle, {
    double vibrance = 1.0,
    double gamma = 1.0,
    double sharpness = 0.0,
    double clarity = 0.0,
  }) {
    final fn = _applyEffects;
    if (fn == null) return false;
    return fn(handle, vibrance, gamma, sharpness, clarity) != 0;
  }
}
