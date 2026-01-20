import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_submit_button_widget.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart'; // Assuming you use GoogleFonts, if not remove and use TextStyle

class MainWorkspaceView extends StatefulWidget {
  final ClientSession session;
  const MainWorkspaceView({super.key, required this.session});

  @override
  State<MainWorkspaceView> createState() => _MainWorkspaceViewState();
}

class _MainWorkspaceViewState extends State<MainWorkspaceView> {
  String? _selectedTarget;
  final List<String> _droppedImages = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          _buildHeader(),
          const Gap(32),

          // // 2. Dropdown Section
          // _buildTargetSelection(),
          // const Gap(24),

          // // 3. "OR DROP BELOW" Divider
          // _buildDivider(),
          // const Gap(24),

          // 4. Drop Zone (Expanded)
          Expanded(child: _buildDropZone()),
          const Gap(24),

          // 5. Button
          _buildCreateArtButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image Editing Workspace',
          style: GoogleFonts.poppins(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Gap(8),
        Text(
          'Configure your final artwork parameters.',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTargetSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select which image you want to create art for',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF1F242F), // Darker background for input
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1F242F),
              hint: Text(
                'Choose an edited image...',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              value: _selectedTarget,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTarget = newValue;
                });
              },
              items: <String>['Image 1', 'Image 2', 'Image 3']
                  .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  })
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white10)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "OR DROP BELOW",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _buildDropZone() {
    return DragTarget<String>(
      onAccept: (receivedPath) {
        setState(() {
          if (!_droppedImages.contains(receivedPath)) {
            _droppedImages.add(receivedPath);
          }
        });
      },
      onWillAccept: (data) => data != null,
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return DottedBorder(
          color: isHovering ? Colors.blueAccent : Colors.white12,
          strokeWidth: 1.5,
          dashPattern: const [6, 6],
          borderType: BorderType.RRect,
          radius: const Radius.circular(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isHovering
                  ? Colors.blue.withOpacity(0.05)
                  : Colors.transparent, // Transparent to match dark bg
              borderRadius: BorderRadius.circular(16),
            ),
            child: _droppedImages.isEmpty
                ? _buildEmptyStateContent()
                : _buildDroppedImagesGrid(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Circular Icon Background
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF252A33), // Slightly lighter circle
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 28,
            color: Color(0xFF9CA3AF), // Grey icon
          ),
        ),
        const Gap(16),
        Text(
          'Drag Image Here',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const Gap(8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            'Drag an edited image from the left panel to populate the workspace.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDroppedImagesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _droppedImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final imagePath = _droppedImages[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _droppedImages.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreateArtButton(BuildContext context) {
    final bool isDisabled = _droppedImages.isEmpty;
    return SizedBox(
      width: double.infinity,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: GlobalSubmitButtonWidget(
          icon: "assets/Icons/brush.svg",
          svgColor: Colors.white,
          title: 'Proceed to art studio',
          // The custom widget requires a non-null callback.
          // If empty, we pass an empty function so it does nothing when clicked.
          onPressed: () {
            if (_droppedImages.isEmpty) {
              // Show error toast if list is empty
              ToastService.showError(
                context,
                title: "No Images Selected",
                message: "Please drop at least one image into the workspace.",
              );
            } else {
              // Show success toast and navigate if images exist
              ToastService.showSuccess(
                context,
                title: "Starting Studio",
                message:
                    "Navigating to Art Studio with ${_droppedImages.length} images.",
              );

              // Use GoRouter to navigate to the art studio route
              // Adjust 'art-studio' to match the actual route name defined in your AppRouter
              context.goNamed(
                'art-studio',
                extra: {
                  'imageUrls': _droppedImages, // The list of images
                  'session': widget
                      .session, // The session object (Make sure your widget has access to it)
                },
              );
            }
          },
        ),
      ),
    );
  }
}
