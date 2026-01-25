import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';
import 'package:iris_designer/Features/EDITOR/Domain/services/color_adjustment_dart.dart';

class ColorAdjustmentView extends StatelessWidget {
  final IrisImage activeImage;
  final double brightness;
  final double contrast;
  final double saturation;
  final double vibrance;
  final ColorPreset? selectedPreset;
  final void Function(double b, double c, double s, double v)
  onAdjustmentChanged;
  final void Function(ColorPreset? preset) onPresetSelected;
  final VoidCallback onReset;

  const ColorAdjustmentView({
    super.key,
    required this.activeImage,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.vibrance,
    required this.selectedPreset,
    required this.onAdjustmentChanged,
    required this.onPresetSelected,
    required this.onReset,
  });




  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left: image on black (larger)
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: _buildPreview(),
          ),
        ),
        // Right: adjustments panel (dark grey) — slightly wider
        Expanded(
          flex: 2,
          child: Container(
            color: const Color(0xFF2A3441),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAdjustmentsHeader(context),
                  const SizedBox(height: 24),
                  _buildSlider(
                    context,
                    'Brightness',
                    brightness,
                    -100,
                    100,
                    (v) =>
                        onAdjustmentChanged(v, contrast, saturation, vibrance),
                  ),
                  const SizedBox(height: 20),
                  _buildSlider(
                    context,
                    'Contrast',
                    contrast,
                    -100,
                    100,
                    (v) => onAdjustmentChanged(
                      brightness,
                      v,
                      saturation,
                      vibrance,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSlider(
                    context,
                    'Saturation',
                    saturation,
                    -100,
                    100,
                    (v) =>
                        onAdjustmentChanged(brightness, contrast, v, vibrance),
                  ),
                  const SizedBox(height: 20),
                  _buildSlider(
                    context,
                    'Vibrance',
                    vibrance,
                    -100,
                    100,
                    (v) => onAdjustmentChanged(
                      brightness,
                      contrast,
                      saturation,
                      v,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildColorPresetsSection(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return SizedBox.expand( // Forces the child to fill the parent Container
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(_buildPreviewMatrix()),
        child: Image.file(
          File(activeImage.imagePath),
          // BoxFit.contain: Largest possible while maintaining ratio (no distortion)
          // BoxFit.fill: Stretches to touch all 4 corners (may distort)
          fit: BoxFit.contain, 
          filterQuality: FilterQuality.medium,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  List<double> _buildPreviewMatrix() {
    const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final b = (1.0 + brightness / 100.0).clamp(0.0, 3.0);
    final c = (1.0 + contrast / 100.0).clamp(0.0, 2.0);
    final s =
        (1.0 + saturation / 100.0) * (1.0 + vibrance / 100.0).clamp(0.0, 2.0);
    final isGrey = selectedPreset == ColorPreset.grey;
    final sat = isGrey ? 0.0 : s;
    final invSat = 1.0 - sat.clamp(0.0, 2.0);
    final invC = (1.0 - c).clamp(0.0, 2.0);
    final trans = 128 * invC;
    final t = b * c;
    return [
      t * (invSat * lumR + sat),
      t * invSat * lumG,
      t * invSat * lumB,
      0,
      trans,
      t * invSat * lumR,
      t * (invSat * lumG + sat),
      t * invSat * lumB,
      0,
      trans,
      t * invSat * lumR,
      t * invSat * lumG,
      t * (invSat * lumB + sat),
      0,
      trans,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  Widget _buildAdjustmentsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Adjustments',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onReset,
          child: const Text(
            'Reset',
            style: TextStyle(color: Color(0xFF60A5FA), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final range = max - min;
    final norm = (value - min) / range;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            Text(
              value.round().toString(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: norm.clamp(0.0, 1.0),
            onChanged: (v) => onChanged(min + v * range),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPresetsSection(BuildContext context) {
    const presets = ColorPreset.all;
    // Natural human iris colors for each preset (blue, green, brown, hazel, black, grey).
    const colors = [
      Color(0xFF4A6FA5), // Blue — soft blue iris
      Color(0xFF4A7C59), // Green — natural green iris
      Color(0xFF5C4033), // Brown — warm brown iris
      Color(0xFF9A7B4F), // Hazel — golden-green-brown
      Color(0xFF2D2D2D), // Black — very dark iris
      Color(0xFF6B7280), // Grey — grey/silver iris
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Presets',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 20,
          children: List.generate(presets.length, (i) {
            final p = presets[i];
            final isSelected = selectedPreset == p;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onPresetSelected(isSelected ? null : p),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i],
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.name,
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
