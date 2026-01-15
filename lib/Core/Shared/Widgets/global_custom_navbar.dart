import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onArrowPressed;
  final String helpDialogNum;
  final String? subtitle;

  const CustomNavBar({
    super.key,
    required this.title,
    required this.onArrowPressed,
    required this.helpDialogNum,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF181E28), // Matches your background
      elevation: 1, // Removes shadow for flat look
      // centerTitle: true, // Centers the image+text row
      // 1. LEFT SIDE (Leading): Back Arrow
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: Colors.white,
        ),
        onPressed: onArrowPressed,
      ),
      // 2. MIDDLE (Title): Image and Text Row
      title: Row(
        // Keeps row tight to content
        children: [
          // Replace this with your actual asset
          // Image.asset('assets/Images/logo_small.png', height: 24),
          const Icon(Icons.remove_red_eye, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Iris designer",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2), // Tiny gap
                Text(
                  "Working on : ${subtitle}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),

      // 3. RIGHT SIDE (Actions): Question Mark
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.grey),
          onPressed: () => _showHelpDialog(context),
        ),

        const SizedBox(width: 16), // Right padding
      ],
    );
  }

  // Necessary for AppBar to know its height
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// ✅ Logic to select content based on the Screen Number
  void _showHelpDialog(BuildContext context) {
    String dialogTitle = "Guide";
    List<Map<String, String>> steps = [];

    switch (helpDialogNum) {
      case '2': // Image Prep 1 (Upload)
        dialogTitle = "Upload Guide";
        steps = [
          {
            "number": "1",
            "title": "Upload Images",
            "desc": "Click the dotted area to upload up to 6 iris images.",
          },
          {
            "number": "2",
            "title": "Review",
            "desc": "Verify the images in the grid before proceeding.",
          },
          {
            "number": "3",
            "title": "Proceed",
            "desc": "Click 'Go Edit' to send these images to the editor.",
          },
        ];
        break;

      case '3': // Editor
        dialogTitle = "Editor Guide";
        steps = [
          {
            "number": "1",
            "title": "Circling",
            "desc": "Adjust the boundaries for the Iris and Pupil.",
          },
          {
            "number": "2",
            "title": "Flash Fix",
            "desc": "Use the brush tool to remove flash reflections.",
          },
          {
            "number": "3",
            "title": "Color",
            "desc": "Enhance the iris colors using sliders and presets.",
          },
        ];
        break;

      case '4': // Image Prep 2 (Workspace)
        dialogTitle = "Workspace Guide";
        steps = [
          {
            "number": "1",
            "title": "Drag & Drop",
            "desc":
                "Drag edited images from the left panel into the workspace.",
          },
          {
            "number": "2",
            "title": "Selection",
            "desc": "You can remove images by clicking the 'X' icon.",
          },
          {
            "number": "3",
            "title": "Create Art",
            "desc": "Click 'Create Art' to move to the final layout studio.",
          },
        ];
        break;

      case '5': // Art Studio
        dialogTitle = "Studio Guide";
        steps = [
          {
            "number": "1",
            "title": "Choose Effect",
            "desc": "Select a style from the gallery. It applies immediately.",
          },
          {
            "number": "2",
            "title": "Configure Layout",
            "desc": "Use controls to select print size (A4, A3) and alignment.",
          },
          {
            "number": "3",
            "title": "Preview",
            "desc": "Click 'SHOW' to generate the high-quality render.",
          },
        ];
        break;

      default:
        dialogTitle = "Help";
        steps = [
          {
            "number": "!",
            "title": "Info",
            "desc": "No specific guide available for this screen.",
          },
        ];
    }

    // Show the generic styled dialog with the specific data
    showDialog(
      context: context,
      builder: (context) => _StyledHelpDialog(title: dialogTitle, steps: steps),
    );
  }
}

/// -------------------------------------------------------------------------
/// ✅ REUSABLE STYLED DIALOG WIDGET (Private)
/// -------------------------------------------------------------------------
class _StyledHelpDialog extends StatelessWidget {
  final String title;
  final List<Map<String, String>> steps;

  const _StyledHelpDialog({required this.title, required this.steps});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B), // Dark container color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.all(24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.all(24),

      // --- TITLE ---
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tips_and_updates,
              color: Colors.blueAccent,
              size: 20,
            ),
          ),
          const Gap(12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),

      // --- DYNAMIC CONTENT ---
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildHelpStep(
                  number: step['number']!,
                  title: step['title']!,
                  description: step['desc']!,
                ),
              );
            }).toList(),
          ),
        ),
      ),

      // --- ACTION BUTTON ---
      actions: [
        SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Got it",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- HELPER FOR STEP ROWS ---
  Widget _buildHelpStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number Bubble
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          child: Text(
            number,
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const Gap(16),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Gap(4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
