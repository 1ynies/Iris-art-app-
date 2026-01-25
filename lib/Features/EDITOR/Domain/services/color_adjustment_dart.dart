import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Preset names for iris color adjustment. Hue shifts in degrees; Gray = desaturate.
/// Optional brightness/contrast/saturation/vibrance (on -100..100) enhance that eye color when selected.
class ColorPreset {
  final String name;
  final double? hueDeg; // null = use saturation 0 (gray)
  final double brightness;
  final double contrast;
  final double saturation;
  final double vibrance;

  const ColorPreset(
    this.name,
    this.hueDeg, {
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.vibrance = 0,
  });

  /// Blue: natural blue iris — boost saturation & vibrance, slight contrast.
  static const blue = ColorPreset('Blue', -30, saturation: 24, vibrance: 18, contrast: 8);
  /// Green: natural green iris — stronger saturation and vibrance.
  static const green = ColorPreset('Green', 100, saturation: 22, vibrance: 18, contrast: 6);
  /// Brown: natural brown iris — warmer, richer tone.
  static const brown = ColorPreset('Brown', 25, saturation: 20, vibrance: 14, brightness: 4, contrast: 6);
  /// Hazel: natural hazel iris — balanced boost for multi-tonal irises.
  static const hazel = ColorPreset('Hazel', 45, saturation: 18, vibrance: 16, contrast: 6);
  /// Black: very dark iris — subtle contrast and brightness to bring out depth.
  static const black = ColorPreset('Black', 20, brightness: 6, contrast: 10, saturation: 8, vibrance: 4);
  /// Grey: desaturate for grey/silver iris look.
  static const grey = ColorPreset('Grey', null, saturation: -100, vibrance: -80);

  static const List<ColorPreset> all = [blue, green, brown, hazel, black, grey];
}

/// Params for Dart-only color adjustment. Slider values typically -100..100; 0 = no change.
class ColorAdjustParams {
  final double brightness;
  final double contrast;
  final double saturation;
  final double vibrance;
  final ColorPreset? preset;

  const ColorAdjustParams({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.vibrance = 0,
    this.preset,
  });
}

/// [args] = [inputPath, outputPath, brightness, contrast, saturation, vibrance, hueDeg?, isGray].
/// Returns output path or null. Synchronous for use in compute().
String? _applyColorAdjustmentSync(List<Object?> args) {
  final inputPath = args[0] as String;
  final outputPath = args[1] as String;
  final brightness = (args[2] as num).toDouble();
  final contrast = (args[3] as num).toDouble();
  final saturation = (args[4] as num).toDouble();
  final vibrance = (args[5] as num).toDouble();
  final hueDeg = args[6] as double?;
  final isGray = args[7] as bool;

  final bytes = File(inputPath).readAsBytesSync();
  img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  if (decoded.hasPalette) decoded = decoded.convert(numChannels: decoded.numChannels);

  final brightMul = (1.0 + brightness / 100.0).clamp(0.0, 3.0);
  final contrastMul = (1.0 + contrast / 100.0).clamp(0.0, 2.0);
  num sat = (1.0 + saturation / 100.0) * (1.0 + vibrance / 100.0);
  sat = sat.clamp(0.0, 2.0);
  if (isGray) sat = 0.0;

  img.Image out = img.adjustColor(
    decoded,
    brightness: brightMul,
    contrast: contrastMul,
    saturation: sat,
    hue: hueDeg,
    amount: 1.0,
  );

  final png = img.encodePng(out);
  File(outputPath).writeAsBytesSync(png);
  return outputPath;
}

/// Applies color adjustments in pure Dart using the image package. Runs on compute isolate.
Future<String?> applyColorAdjustmentDart({
  required String inputPath,
  required ColorAdjustParams params,
}) async {
  final tempDir = await getTemporaryDirectory();
  final outputPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.png';
  final args = [
    inputPath,
    outputPath,
    params.brightness,
    params.contrast,
    params.saturation,
    params.vibrance,
    params.preset?.hueDeg,
    params.preset == ColorPreset.grey,
  ];
  return compute(_applyColorAdjustmentSync, args);
}
