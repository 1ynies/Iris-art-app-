import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/widgets/client_info_card.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/widgets/status_chip_widget.dart';

class ImagePrepView2 extends StatefulWidget {
  final List<String>? preloadedImages;
  final ClientSession session;

  const ImagePrepView2({
    super.key,
    required this.session,
    this.preloadedImages,
  });

  @override
  State<ImagePrepView2> createState() => _ImagePrepView2State();
}

class _ImagePrepView2State extends State<ImagePrepView2> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 1. Load basic project data (DB)
    context.read<ProjectHubBloc>().add(LoadProjectData(widget.session.id));

    // ✅ 2. CRITICAL FIX: If we have images from Editor, put them in the Bloc!
    if (widget.preloadedImages != null && widget.preloadedImages!.isNotEmpty) {
      for (var path in widget.preloadedImages!) {
        // We trigger an upload/add event for each existing image
        // to ensure the UI state matches the passed list immediately.
        context.read<ProjectHubBloc>().add(
          UploadImageTriggered(projectId: widget.session.id, imagePath: path),
        );
      }
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final String filePath = result.files.single.path!;
      final state = context.read<ProjectHubBloc>().state;

      if (state is ProjectHubLoaded) {
        if (state.project.imageUrls.length >= 6) {
          ToastService.showError(
            context,
            title: "Limit Reached",
            message: "Max 6 images allowed.",
          );
          return;
        }
        if (state.project.imageUrls.contains(filePath)) {
          ToastService.showError(
            context,
            title: "Duplicate",
            message: "Image already added.",
          );
          return;
        }
      }

      if (context.mounted) {
        context.read<ProjectHubBloc>().add(
          UploadImageTriggered(
            projectId: widget.session.id,
            imagePath: filePath,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Gap(32),
          // 1. Client Info Card
          ClientInfoCard(
            name: widget.session.clientName,
            email: widget.session.email,
            location: widget.session.country,
          ),

          const SizedBox(height: 32),

          // 2. The Dynamic Area (Always shows Grid)
          Expanded(child: _buildGallerySection(context)),
        ],
      ),
    );
  }

  Row _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Prep',
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select assets for workspace',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        StatusChip(label: 'ACTIVE SESSION'),
      ],
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    return BlocBuilder<ProjectHubBloc, ProjectHubState>(
      builder: (context, state) {
        List<String> images = [];
        // bool hasImages = false; // ❌ Removed checks

        if (state is ProjectHubLoaded) {
          images = state.project.imageUrls;
          // hasImages = images.isNotEmpty;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edited Images',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'DRAG TO WORKSPACE',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),

                // ✅ Always show Add Button so you can upload even if empty
              ],
            ),
            const SizedBox(height: 16),

            // --- GRID SECTION ---
            // ✅ Always showing Grid (no empty state widget)
            Expanded(child: _buildDraggableGrid(images)),

            // Footer text
            // Padding(
            //   padding: const EdgeInsets.only(top: 12.0),
            //   child: Text(
            //     "${images.length} / 6 Images Uploaded",
            //     style: const TextStyle(color: Colors.grey, fontSize: 12),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  // ✅ WIDGET 1: THE DRAGGABLE GRID
  Widget _buildDraggableGrid(List<String> images) {
    return GridView.builder(
      itemCount: images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 2 images per row
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0, // Ensures perfect squares
      ),

      itemBuilder: (context, index) {
        final String imagePath = images[index];

        // 🟢 DRAGGABLE WRAPPER
        return Draggable<String>(
          data: imagePath, // The data passed when dropped
          // 1. What you see UNDER your finger while dragging
          feedback: SizedBox(
            // width: 120,
            // height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.8),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),

          // 2. What r
          //emains in the grid (Ghost)
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _buildSquareImage(imagePath),
          ),

          // 3. Normal appearance
          child: _buildSquareImage(imagePath),
        );
      },
    );
  }

  // Helper to build the square image tile
  Widget _buildSquareImage(String path) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF2A3441),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          width: 120, // Takes full width of square
          height: 120, // Takes full height of square
          fit: BoxFit.cover, // Fills space, no empty gaps
          errorBuilder: (c, e, s) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
