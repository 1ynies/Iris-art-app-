import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

//! Update the colors and color adjustment screen 
//!add a - + button on top right of the image placeholder to be able to zoom 


class ColorAdjustmentView extends StatelessWidget {
  final IrisImage activeImage;
  
  // State variables passed from parent
  final double brightness;
  final double contrast;
  final double saturation;
  final Color? tintColor;
  
  // Callback to update parent state
  final Function(double b, double c, double s, Color? t) onAdjustmentChanged;
  
  // ✅ ADDED: Undo Callback
  final VoidCallback? onUndo;

  const ColorAdjustmentView({
    super.key, 
    required this.activeImage,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.tintColor,
    required this.onAdjustmentChanged,
    this.onUndo, // ✅ Optional parameter for Undo
  });

  // Matrix Logic for Real-time Preview
  ColorFilter _getMatrixFilter() {
    // Contrast (1.0 = normal)
    double c = 1.0 + contrast;
    double o = 128 * (1 - c); 

    // Brightness (0.0 = normal)
    double b = brightness * 255;

    // Saturation (1.0 = normal)
    double s = 1.0 + saturation;
    
    // Luminance constants for saturation
    const double lumR = 0.2126;
    const double lumG = 0.7152;
    const double lumB = 0.0722;

    double sr = (1 - s) * lumR;
    double sg = (1 - s) * lumG;
    double sb = (1 - s) * lumB;

    return ColorFilter.matrix([
      c * (sr + s), c * sg,       c * sb,       0, o + b,
      c * sr,       c * (sg + s), c * sb,       0, o + b,
      c * sr,       c * sg,       c * (sb + s), 0, o + b,
      0,            0,            0,            1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Image Preview
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black,
            // ✅ ADDED: InteractiveViewer for Zoom & Pan
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 5.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: ColorFiltered(
                  colorFilter: _getMatrixFilter(), // Apply B/C/S
                  child: ColorFiltered(
                    // Apply Tint (if selected)
                    colorFilter: ColorFilter.mode(
                      tintColor?.withOpacity(0.3) ?? Colors.transparent, 
                      BlendMode.srcATop
                    ),
                    child: Image.file(
                      File(activeImage.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Controls Panel
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF15191F),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Adjustments",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ✅ ADDED: Undo Button
                          IconButton(
                            icon: const Icon(Icons.undo, color: Colors.grey, size: 20),
                            tooltip: "Undo",
                            onPressed: onUndo,
                          ),
                          const Gap(8),
                          TextButton(
                            // Reset Logic
                            onPressed: () => onAdjustmentChanged(0, 0, 0, null),
                            child: const Text(
                              "Reset",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(20),
                  
                  // Wired up Sliders
                  _buildSlider("Brightness", brightness, -0.5, 0.5, (v) => onAdjustmentChanged(v, contrast, saturation, tintColor)),
                  _buildSlider("Contrast", contrast, -0.8, 0.8, (v) => onAdjustmentChanged(brightness, v, saturation, tintColor)),
                  _buildSlider("Saturation", saturation, -0.8, 0.8, (v) => onAdjustmentChanged(brightness, contrast, v, tintColor)),
                  
                  // Placeholder for Vibrance mapped to Saturation for now
                  _buildSlider("Vibrance", saturation / 2, -0.5, 0.5, (v) => onAdjustmentChanged(brightness, contrast, v * 2, tintColor)), 

                  const Gap(24),
                  const Text(
                    "Color Presets",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildColorPreset(Colors.blue, "Blue"),
                      _buildColorPreset(Colors.brown, "Brown"),
                      _buildColorPreset(Colors.amber, "Hazel"),
                      _buildColorPreset(Colors.green, "Green"),
                      _buildColorPreset(Colors.grey, "Gray"),
                      _buildColorPreset(Colors.purple, "Violet"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              "${(val * 100).toInt()}",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
        SizedBox(
          height: 30,
          child: Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: Colors.white,
            inactiveColor: Colors.white10,
            thumbColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPreset(Color color, String label) {
    bool isActive = tintColor == color;
    
    return GestureDetector(
      onTap: () {
        if (isActive) {
          onAdjustmentChanged(brightness, contrast, saturation, null);
        } else {
          onAdjustmentChanged(brightness, contrast, saturation, color);
        }
      },
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              shape: BoxShape.circle,
              border: isActive ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: isActive 
                ? const Icon(Icons.check, size: 20, color: Colors.white) 
                : null,
          ),
          const Gap(4),
          Text(label, style: TextStyle(
            color: isActive ? Colors.white : Colors.grey, 
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }
}