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
    // ✅ Wrapped in Center -> SingleChildScrollView to allow scrolling while keeping content centered if possible
    return  SingleChildScrollView(
        // padding: const EdgeInsets.symmetric(vertical: 20), // Add padding for scroll breathing room
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center, // Center vertical content
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

            const Gap(20),

              Text(
                "DUO EFFECTS",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            
          
              const Gap(12),

            // 3. DUO EFFECTS ROW
            if (duoEffects.isNotEmpty) // ✅ Only show if effects exist
              SizedBox(
                height: 300, // Adjusted height to fit 220px item + text
                width: double.infinity, // ✅ Takes full horizontal space
                child: Center(
                  // ✅ Center wraps ListView + shrinkWrap:true centers items if they don't overflow
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true, // ✅ Essential for centering content
                    padding: EdgeInsets.zero, // ✅ UPDATED: Removed padding
                    itemCount: duoEffects.length,
                    separatorBuilder: (_, __) => const Gap(30),
                    itemBuilder: (context, index) {
                      final item = duoEffects[index];
                      final bool isSelected = item['name'] == effect;

                      return GestureDetector(
                        onTap: () => onEffectSelected(item['name']),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 220, // ✅ Big Size
                              height: 220, // ✅ Big Size
                              decoration: BoxDecoration(
                                color: (item['color'] as Color).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: Colors.blueAccent, width: 2)
                                    : Border.all(color: Colors.transparent),
                              ),
                              child: Center(
                                child: Icon(Icons.blur_on,
                                    color: item['color'], size: 40),
                              ),
                            ),
                            const Gap(12),
                            Text(
                              item['name'].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.grey,
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
        ),
      
    );
  }
}