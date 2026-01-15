import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructionView extends StatelessWidget {
  final String clientName;
  const InstructionView({super.key, required this.clientName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(64.0),
      color: const Color(0xFF181E28), // Match main background
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Icon ---
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A3441), // Lighter grey-blue circle
                  shape: BoxShape.circle,
                ),
                // Padding inside ensures the SVG isn't too big
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  "assets/Icons/eye_solid.svg",
                  // Using colorFilter is the modern way to color SVGs
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF94A3B8), // Light grey icon color
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF007BFF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const Gap(48),

          // --- Rich Text Title ---
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              children: [
                const TextSpan(text: 'Please proceed on the\nediting of '),
                TextSpan(
                  text: "$clientName \'s",
                  style: const TextStyle(color: Color(0xFF007BFF)),
                ),
                const TextSpan(text: ' iris.'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Description Text ---
           Text(
            'Review the assets in the left panel. Once you are satisfied with the selection, click continue to start the rendering process.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
