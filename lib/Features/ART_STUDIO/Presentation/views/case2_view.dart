import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/iris_placeholder.dart';

class Case2View extends StatelessWidget {
  final String effect;
  final List<String> images;
  final List<Map<String, dynamic>> duoEffects;
  final Function(String) onEffectSelected;

  const Case2View({
    super.key,
    required this.effect,
    required this.images,
    required this.duoEffects,
    required this.onEffectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center vertical content
      children: [
        // 1. THE CANVAS
        Container(
          width: 420,
          height: 420,
          padding: const EdgeInsets.all(20), // Reduced padding for better fit
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
          child: Stack(
            fit: StackFit.expand, // ✅ Fix: Make stack fill the container
            children: [
              // Top Right Image
              Positioned(
                top: 0,
                right: 0,
                width: 190, // ✅ Dynamic half-width roughly
                height: 190,
                child: IrisPlaceholder(
                  imagePath: images.isNotEmpty ? images[0] : null,
                  // Remove fixed size, let it fill the Positioned box
                ),
              ),
              
              // Bottom Left Image
              Positioned(
                bottom: 0,
                left: 0,
                width: 190, // ✅ Dynamic half-width roughly
                height: 190,
                child: IrisPlaceholder(
                  imagePath: images.length > 1 ? images[1] : null,
                ),
              ),
            ],
          ),
        ),

        const Gap(24),

        // 2. SELECTED EFFECT TEXT
        Text(
          "SELECTED EFFECT: ${effect.toUpperCase()}",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w500,
          ),
        ),

        const Gap(32),

        // 3. DUO EFFECTS ROW
        if (duoEffects.isNotEmpty) // ✅ Only show if effects exist
          SizedBox(
            height: 160, // Adjusted height
            width: double.infinity,
            child: Center(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: duoEffects.length,
                separatorBuilder: (_, __) => const Gap(24),
                itemBuilder: (context, index) {
                  final item = duoEffects[index];
                  final bool isSelected = item['name'] == effect;

                  return GestureDetector(
                    onTap: () => onEffectSelected(item['name']),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120, // Reduced from 200 for better fit
                          height: 120,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Colors.blueAccent, width: 2)
                                : Border.all(color: Colors.transparent),
                          ),
                          child: Center(
                            child: Icon(Icons.blur_on, color: item['color'], size: 40),
                          ),
                        ),
                        const Gap(12),
                        Text(
                          item['name'].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            color: isSelected ? Colors.blueAccent : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}