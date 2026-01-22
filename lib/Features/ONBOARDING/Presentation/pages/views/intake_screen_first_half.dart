import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Config/Theme.dart';

class LeftPromotionalView extends StatelessWidget {
  const LeftPromotionalView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.backgroundDark,
        child: Center(
          // 2. Add SingleChildScrollView to allow scrolling when screen is small
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 80,
              right: 80,
              bottom: 80,
              top: 80,
            ),
            // Centering vertically
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/Images/appicon.png',
                      width: 40,
                      height: 40,
                    ),
                    Gap(10),
                    Text(
                      'Iris designer',
                      style: GoogleFonts.poppins(
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(25),
                Text(
                  "Discover the art\nhidden in your\neyes",
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      height: 1,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  "We help you create stunning iris artwork from high-resolution eye photographs.Our tools transform unique biological patterns into timeless masterpieces .",
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Color(0xFF687890),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // The image section with overlay chips
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      // Placeholder for the actual eye image.
                      // In a real app, replace Image.network with Image.asset
                      // Image.network(
                      //   'https://picsum.photos/id/1025/600/350', // Using a placeholder eye/animal image
                      //   width: 500,
                      //   height: 250,
                      //   fit: BoxFit.cover,
                      //   errorBuilder: (ctx, err, stack) => Container(
                      //     height: 250,
                      //     color: Colors.grey.shade800,
                      //     child: const Center(
                      //       child: Icon(Icons.image, color: Colors.white),
                      //     ),
                      //   ),
                      // ),
                      Image.asset(
                        'assets/Images/high-resolution-anatomy-human-eye-highlighting-iris-vasculature_607202-22001-2727869561.jpg',
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                      // Overlay Gradient for readability of chips
                      Container(
                        height: 250,
                        width: 500,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            _buildGlassChip("High Resolution"),
                            const SizedBox(width: 8),
                            _buildGlassChip("Artistic Processing"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
