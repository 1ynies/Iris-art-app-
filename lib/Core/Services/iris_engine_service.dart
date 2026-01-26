import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:iris_designer/Core/Native/native_iris_bridge.dart';

import 'iris_engine_bindings.dart';

/// High-level service: file in → Iris Engine → file out.
/// Runs on main isolate (FFI must run on main). Use from editor: try engine first, then Dart/Photopea.
class IrisEngineService {
  static final _bindings = IrisEngineBindings.instance;
  static final _nativeBridge = NativeIrisBridge.instance;

  static bool get isAvailable => _bindings.isAvailable;

  /// True when Phase 1 cut-and-warp (user circles, radial stretch) is available.
  static bool get isCutAndWarpAvailable =>
      _nativeBridge.isAvailable && _nativeBridge.canCutAndWarp;

  /// True when the native engine was built with OpenCV support.
  static bool get isOpenCvAvailable => _nativeBridge.hasOpenCv;

  static Uint8List? _imageToRgba(img.Image src) {
    final w = src.width;
    final h = src.height;
    if (w <= 0 || h <= 0) return null;
    final out = Uint8List(w * h * 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = src.getPixel(x, y);
        final i = (y * w + x) * 4;
        out[i] = p.r.toInt().clamp(0, 255);
        out[i + 1] = p.g.toInt().clamp(0, 255);
        out[i + 2] = p.b.toInt().clamp(0, 255);
        out[i + 3] = p.a.toInt().clamp(0, 255);
      }
    }
    return out;
  }

  static img.Image? _rgbaToImage(Uint8List rgba, int w, int h) {
    if (rgba.length < w * h * 4) return null;
    final out = img.Image(width: w, height: h, numChannels: 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final i = (y * w + x) * 4;
        out.setPixel(x, y, img.ColorRgba8(rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]));
      }
    }
    return out;
  }

  /// Phase 1: User-defined circles + 50% pupil shrink (radial warp). View params from circling UI.
  /// Returns output path or null. Prefer this when [isCutAndWarpAvailable] and view size is known.
  static Future<String?> processCirclingWithViewParams(
    String inputPath, {
    required double viewW,
    required double viewH,
    required double outerR,
    required double innerR,
    required double outerDx,
    required double outerDy,
    required double innerDx,
    required double innerDy,
  }) async {
    if (!_nativeBridge.isAvailable) return null;
    final result = await _nativeBridge.cutAndWarpIris(
      imagePath: inputPath,
      viewW: viewW,
      viewH: viewH,
      outerR: outerR,
      innerR: innerR,
      outerDx: outerDx,
      outerDy: outerDy,
      innerDx: innerDx,
      innerDy: innerDy,
    );
    if (result == null) return null;
    final out = _rgbaToImage(result.rgba, result.width, result.height);
    if (out == null) return null;
    final tempDir = await getTemporaryDirectory();
    final outPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(Uint8List.fromList(img.encodePng(out)));
    return outPath;
  }

  /// Phase 2: Auto-detect iris/pupil (Hough), cut to alpha. Returns output path or null.
  static Future<String?> processCircling(String inputPath) async {
    if (!_bindings.isAvailable) return null;
    final bytes = File(inputPath).readAsBytesSync();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    if (decoded.hasPalette) decoded = decoded.convert(numChannels: decoded.numChannels);
    final w = decoded.width;
    final h = decoded.height;
    if (w <= 0 || h <= 0) return null;
    final rgba = _imageToRgba(decoded);
    if (rgba == null) return null;

    final handle = _bindings.createHandle();
    if (handle == null) return null;
    try {
      if (!_bindings.loadRgba(handle, rgba, w, h)) return null;
      if (!_bindings.cutIris(handle)) return null;
      if (!_bindings.getRgba(handle, rgba, w, h)) return null;
    } finally {
      _bindings.destroyHandle(handle);
    }

    final out = _rgbaToImage(rgba, w, h);
    if (out == null) return null;
    final tempDir = await getTemporaryDirectory();
    final outPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(Uint8List.fromList(img.encodePng(out)));
    return outPath;
  }

  /// Phase 3: Remove flash. Returns output path or null.
  static Future<String?> processFlashRemoval(String inputPath, {double threshold = 0.95, int dilatePixels = 3}) async {
    if (!_bindings.isAvailable) return null;
    final bytes = File(inputPath).readAsBytesSync();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    if (decoded.hasPalette) decoded = decoded.convert(numChannels: decoded.numChannels);
    final w = decoded.width;
    final h = decoded.height;
    if (w <= 0 || h <= 0) return null;
    final rgba = _imageToRgba(decoded);
    if (rgba == null) return null;

    final handle = _bindings.createHandle();
    if (handle == null) return null;
    try {
      if (!_bindings.loadRgba(handle, rgba, w, h)) return null;
      if (!_bindings.removeFlash(handle, threshold: threshold, dilatePixels: dilatePixels)) return null;
      if (!_bindings.getRgba(handle, rgba, w, h)) return null;
    } finally {
      _bindings.destroyHandle(handle);
    }

    final out = _rgbaToImage(rgba, w, h);
    if (out == null) return null;
    final tempDir = await getTemporaryDirectory();
    final outPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(Uint8List.fromList(img.encodePng(out)));
    return outPath;
  }

  /// Phase 4: Apply effects. brightness/contrast/saturation/vibrance (slider -100..100) map to engine params.
  static Future<String?> processColorEffects(String inputPath, {
    double brightness = 0,
    double contrast = 0,
    double saturation = 0,
    double vibrance = 0,
  }) async {
    if (!_bindings.isAvailable) return null;
    final bytes = File(inputPath).readAsBytesSync();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    if (decoded.hasPalette) decoded = decoded.convert(numChannels: decoded.numChannels);
    final w = decoded.width;
    final h = decoded.height;
    if (w <= 0 || h <= 0) return null;
    final rgba = _imageToRgba(decoded);
    if (rgba == null) return null;

    final g = (1.0 + brightness / 100.0).clamp(0.5, 2.0);
    final v = (1.0 + (saturation + vibrance) / 100.0).clamp(0.0, 2.0);
    final clarity = (1.0 + contrast / 50.0).clamp(0.5, 2.0);

    final handle = _bindings.createHandle();
    if (handle == null) return null;
    try {
      if (!_bindings.loadRgba(handle, rgba, w, h)) return null;
      if (!_bindings.applyEffects(handle, vibrance: v, gamma: g, sharpness: 0.2, clarity: clarity)) return null;
      if (!_bindings.getRgba(handle, rgba, w, h)) return null;
    } finally {
      _bindings.destroyHandle(handle);
    }

    final out = _rgbaToImage(rgba, w, h);
    if (out == null) return null;
    final tempDir = await getTemporaryDirectory();
    final outPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outPath).writeAsBytes(Uint8List.fromList(img.encodePng(out)));
    return outPath;
  }
}
