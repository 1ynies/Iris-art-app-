import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

class ColorAdjustmentView extends StatelessWidget {
  final IrisImage activeImage;
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;
  final Function(double,double,double,double) onAdjustmentChanged;

  const ColorAdjustmentView({
    super.key, required this.activeImage, required this.brightness, required this.contrast, required this.saturation, required this.hue, required this.onAdjustmentChanged
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Live Preview Approximation
    // Since Photopea is now headless, we use Flutter's ColorFiltered for the live preview
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        1.0 + (brightness / 100), 0, 0, 0, 0,
        0, 1.0 + (brightness / 100), 0, 0, 0,
        0, 0, 1.0 + (brightness / 100), 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Image.file(
        File(activeImage.imagePath),
        fit: activeImage.isCirclingDone || activeImage.imagePath.contains('edited_')
            ? BoxFit.cover
            : BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}