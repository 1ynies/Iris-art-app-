// ignore_for_file: unused_element

/// Phase 1: Circling & Cutting — Dart FFI bridge to native process_iris_cut (2026).
/// On Windows, loads iris_engine.dll by name only (via [loadIrisEngine]) so the
/// loader uses the executable directory; no full path is passed.
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:iris_designer/Core/Native/iris_engine_loader.dart';

/// Result of a successful cut-and-warp. RGBA row-major; use with [decodeImageFromPixels].
typedef IrisCutResult = ({
  Uint8List rgba,
  int width,
  int height,
});

// FFI types matching iris_engine_ffi.h
typedef _ProcessIrisCutFromViewNative = Int32 Function(
  Pointer<Utf8> imagePath,
  Double viewW,
  Double viewH,
  Double outerR,
  Double innerR,
  Double outerDx,
  Double outerDy,
  Double innerDx,
  Double innerDy,
  Pointer<Pointer<Uint8>> outRgba,
  Pointer<Int32> outWidth,
  Pointer<Int32> outHeight,
);
typedef _ProcessIrisCutFromViewDart = int Function(
  Pointer<Utf8> imagePath,
  double viewW,
  double viewH,
  double outerR,
  double innerR,
  double outerDx,
  double outerDy,
  double innerDx,
  double innerDy,
  Pointer<Pointer<Uint8>> outRgba,
  Pointer<Int32> outWidth,
  Pointer<Int32> outHeight,
);

typedef _FreeNative = Void Function(Pointer<Void> ptr);
typedef _FreeDart = void Function(Pointer<Void> ptr);
typedef _HasOpenCvNative = Int32 Function();
typedef _HasOpenCvDart = int Function();
typedef _InitNative = Int32 Function();
typedef _InitDart = int Function();

DynamicLibrary? _loadEngine() {
  if (!Platform.isWindows) return null;
  return loadIrisEngine();
}

/// Bridge for Phase 1 cut-and-warp (user-defined circles, 50% pupil shrink, radial stretch).
class NativeIrisBridge {
  NativeIrisBridge._();

  static NativeIrisBridge? _instance;
  static NativeIrisBridge get instance {
    _instance ??= NativeIrisBridge._();
    return _instance!;
  }

  DynamicLibrary? _lib;
  bool _inited = false;

  void _ensureInit() {
    if (_inited) return;
    _inited = true;
    _lib = _loadEngine();
    if (Platform.isWindows && _lib == null) {
      throw Exception(
        'CRITICAL: iris_engine.dll failed to load. Ensure iris_engine.dll and OpenCV DLLs are next to the exe.',
      );
    }
    final init = _init;
    if (Platform.isWindows && init == null) {
      throw Exception(
        'CRITICAL: iris_engine_init symbol missing. Engine DLL is incompatible.',
      );
    }
    if (init != null) {
      final ok = init();
      if (ok == -1) {
        throw Exception(
          'CRITICAL: OpenCV Engine failed to initialize. DLLs missing or incompatible.',
        );
      }
    }
  }

  bool get isAvailable {
    _ensureInit();
    return _lib != null;
  }

  /// True when the DLL exports the cut-and-warp symbol.
  bool get canCutAndWarp => _processFromView != null;

  _ProcessIrisCutFromViewDart? get _processFromView {
    _ensureInit();
    if (_lib == null) return null;
    try {
      return _lib!
          .lookup<NativeFunction<_ProcessIrisCutFromViewNative>>(
              'iris_engine_process_iris_cut_from_view')
          .asFunction<_ProcessIrisCutFromViewDart>();
    } catch (_) {
      return null;
    }
  }

  _FreeDart? get _free {
    _ensureInit();
    if (_lib == null) return null;
    try {
      return _lib!
          .lookup<NativeFunction<_FreeNative>>('iris_engine_free')
          .asFunction<_FreeDart>();
    } catch (_) {
      return null;
    }
  }

  _HasOpenCvDart? get _hasOpenCv {
    _ensureInit();
    if (_lib == null) return null;
    try {
      return _lib!
          .lookup<NativeFunction<_HasOpenCvNative>>('iris_engine_has_opencv')
          .asFunction<_HasOpenCvDart>();
    } catch (_) {
      return null;
    }
  }

  _InitDart? get _init {
    if (_lib == null) return null;
    try {
      return _lib!
          .lookup<NativeFunction<_InitNative>>('iris_engine_init')
          .asFunction<_InitDart>();
    } catch (_) {
      return null;
    }
  }

  /// True when the native engine was built with OpenCV support.
  bool get hasOpenCv => (_hasOpenCv?.call() ?? 0) != 0;

  /// Runs the native cut-and-warp. View params match the circling UI (outer=iris, inner=pupil).
  /// Returns (rgba, width, height) or null if engine unavailable or native returns failure.
  Future<IrisCutResult?> cutAndWarpIris({
    required String imagePath,
    required double viewW,
    required double viewH,
    required double outerR,
    required double innerR,
    required double outerDx,
    required double outerDy,
    required double innerDx,
    required double innerDy,
  }) {
    return Future.microtask(() {
      final fn = _processFromView;
      final freeFn = _free;
      if (fn == null || freeFn == null) return null;
      return using((Arena arena) {
        final pathPtr = imagePath.toNativeUtf8(allocator: arena);
        final pOutRgba = arena.allocate(sizeOf<Pointer<Uint8>>()).cast<Pointer<Uint8>>();
        final pOutW = arena.allocate(sizeOf<Int32>()).cast<Int32>();
        final pOutH = arena.allocate(sizeOf<Int32>()).cast<Int32>();
        final ok = fn(
          pathPtr,
          viewW,
          viewH,
          outerR,
          innerR,
          outerDx,
          outerDy,
          innerDx,
          innerDy,
          pOutRgba,
          pOutW,
          pOutH,
        );
        if (ok != 1) return null;
        final ptr = pOutRgba.value;
        final w = pOutW.value;
        final h = pOutH.value;
        if (ptr == nullptr || w <= 0 || h <= 0) return null;
        final len = w * h * 4;
        final list = ptr.cast<Uint8>().asTypedList(len).toList();
        freeFn(ptr.cast());
        return (rgba: Uint8List.fromList(list), width: w, height: h);
      });
    });
  }
}
