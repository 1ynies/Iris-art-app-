import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_submit_button_widget.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/widgets/client_info_card.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/widgets/status_chip_widget.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/widgets/image_grid_widget.dart';

class ImagePrepView extends StatefulWidget {
  final ClientSession session;
  final List<String>? returnedImages;
  const ImagePrepView({super.key, required this.session, this.returnedImages});

  @override
  State<ImagePrepView> createState() => _ImagePrepViewState();
}

class _ImagePrepViewState extends State<ImagePrepView> {
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 1. Trigger Load (The BLoC will now fetch saved images automatically)
    context.read<ProjectHubBloc>().add(LoadProjectData(widget.session.id));

    // 2. Only handle "returnedImages" (new edits coming back from the editor)
    if (widget.returnedImages != null && widget.returnedImages!.isNotEmpty) {
      for (var path in widget.returnedImages!) {
        context.read<ProjectHubBloc>().add(
          UploadImageTriggered(projectId: widget.session.id, imagePath: path),
        );
      }
    }
  }

  // 🛠️ UPDATED: Detailed Error Reporting & Processing
  void _processFilePaths(BuildContext context, List<String> newPaths) {
    if (newPaths.isEmpty) return;

    final state = context.read<ProjectHubBloc>().state;
    List<String> currentImages = [];
    if (state is ProjectHubLoaded) {
      currentImages = state.project.imageUrls;
    }

    // 1. Check Total Limit First
    if (currentImages.length >= 6) {
      ToastService.showError(
        context,
        title: "Limit Reached",
        message: "You have already reached the 6 image limit.",
      );
      return;
    }

    int addedCount = 0;
    int duplicateCount = 0;
    int invalidFormatCount = 0;
    bool limitHitDuringUpload = false;

    final validExtensions = ['jpg', 'jpeg', 'png'];

    for (var path in newPaths) {
      // Check Extension
      final ext = path.split('.').last.toLowerCase();
      if (!validExtensions.contains(ext)) {
        invalidFormatCount++;
        continue;
      }

      // Check Remaining Slots
      if ((currentImages.length + addedCount) >= 6) {
        limitHitDuringUpload = true;
        // Don't break immediately, we might want to count how many were ignored
        continue; 
      }

      // Check Duplicates
      if (currentImages.contains(path)) {
        duplicateCount++;
        continue;
      }

      // Add
      if (context.mounted) {
        context.read<ProjectHubBloc>().add(
          UploadImageTriggered(projectId: widget.session.id, imagePath: path),
        );
        addedCount++;
      }
    }

    // 🛠️ SMART TOAST LOGIC
    if (addedCount > 0) {
      // Success Message
      String msg = "$addedCount images added.";
      if (limitHitDuringUpload) msg += " (Stopped at limit).";
      
      ToastService.showSuccess(
        context,
        title: "Upload Successful",
        message: msg,
      );
    } else if (limitHitDuringUpload && addedCount == 0) {
      // Limit Error
      ToastService.showError(
        context,
        title: "Limit Reached",
        message: "No space left. Max 6 images allowed.",
      );
    } else if (duplicateCount > 0 && addedCount == 0) {
      // Duplicate Error
      ToastService.showError(
        context,
        title: "Duplicates Ignored",
        message: "Selected images are already in the project.",
      );
    } else if (invalidFormatCount > 0 && addedCount == 0) {
      // Invalid Format Error
      ToastService.showError(
        context,
        title: "Invalid Format",
        message: "Only JPG and PNG files are allowed.",
      );
    } 
    
    // Mixed Warnings (if needed)
    if (addedCount > 0 && (duplicateCount > 0 || invalidFormatCount > 0)) {
      // If we added some, but skipped others, maybe show a small warning toast *after* success? 
      // Or just rely on the user seeing only some files appeared. 
      // For professional apps, usually just showing the success count is cleaner, 
      // unless ALL failed.
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    // Basic check before opening picker
    final state = context.read<ProjectHubBloc>().state;
    if (state is ProjectHubLoaded && state.project.imageUrls.length >= 6) {
       ToastService.showError(context, title: "Limit Reached", message: "Max 6 images allowed.");
       return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );

    if (result != null && context.mounted) {
      final paths = result.files.map((e) => e.path).whereType<String>().toList();
      _processFilePaths(context, paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ MOVED DROP TARGET TO THE ROOT (Wraps Scaffold)
    // This ensures dragging anywhere on the window triggers the event.
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        final paths = details.files.map((e) => e.path).toList();
        _processFilePaths(context, paths);
      },
      child: Scaffold(
        // ✅ Add a visual overlay for the whole screen when dragging
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Section ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Image Prep',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Upload assets',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                        StatusChip(label: 'ACTIVE SESSION'),
                      ],
                    ),
                    const Gap(20),
      
                    // --- Client Info Card ---
                    ClientInfoCard(
                      name: widget.session.clientName,
                      email: widget.session.email,
                      location: widget.session.country,
                    ),
                    const SizedBox(height: 20),
      
                    // --- Main Content Area ---
                    BlocBuilder<ProjectHubBloc, ProjectHubState>(
                      builder: (context, state) {
                        bool hasImages = false;
                        List<String> images = [];
                        if (state is ProjectHubLoaded) {
                          images = state.project.imageUrls;
                          hasImages = images.isNotEmpty;
                        }
      
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Iris Images',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Supported: JPG, PNG, JPEG',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasImages)
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(context),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add More'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF242C38),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      side: const BorderSide(color: Colors.white12),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
      
                            // --- Upload Zone / Grid ---
                            if (!hasImages)
                              InkWell(
                                onTap: () => _pickImage(context),
                                child: DottedBorder(
                                  // Highlight border if dragging over
                                  color: _isDragging 
                                      ? Colors.blueAccent 
                                      : const Color(0xFF687890),
                                  strokeWidth: _isDragging ? 3 : 2,
                                  dashPattern: const [8, 4],
                                  borderType: BorderType.RRect,
                                  radius: const Radius.circular(12),
                                  child: Container(
                                    height: 250,
                                    width: double.infinity,
                                    // Make sure container has a color to catch hits
                                    color: _isDragging 
                                        ? Colors.blue.withOpacity(0.1) 
                                        : Colors.transparent, 
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2A3441),
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: SvgPicture.asset(
                                            "assets/Icons/arrow_up_tray.svg",
                                            colorFilter: ColorFilter.mode(
                                              _isDragging 
                                                ? Colors.blueAccent 
                                                : const Color(0xFF94A3B8),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                        const Gap(8),
                                        Text(
                                          _isDragging 
                                            ? 'Release to upload' 
                                            : 'Click or Drag to upload images',
                                          style: GoogleFonts.poppins(
                                            textStyle: TextStyle(
                                              fontSize: 15,
                                              color: _isDragging 
                                                  ? Colors.blueAccent 
                                                  : Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
      
                            if (hasImages)
                              ImageGrid(
                                images: images,
                                onDelete: (pathToDelete) {
                                  context.read<ProjectHubBloc>().add(
                                    RemoveImageTriggered(imagePath: pathToDelete),
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
      
                    const SizedBox(height: 16),
      
                    // --- Bottom Info ---
                    BlocBuilder<ProjectHubBloc, ProjectHubState>(
                      builder: (context, state) {
                        int count = (state is ProjectHubLoaded) ? state.project.imageUrls.length : 0;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$count images uploaded',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Text(
                              'Max 6',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
      
                    // --- Continue Button ---
                    BlocBuilder<ProjectHubBloc, ProjectHubState>(
                      builder: (context, state) {
                        bool hasImages = false;
                        List<String> currentPaths = [];
                        if (state is ProjectHubLoaded) {
                          currentPaths = state.project.imageUrls;
                          hasImages = currentPaths.isNotEmpty;
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: Opacity(
                                opacity: hasImages ? 1.0 : 0.5,
                                child: GlobalSubmitButtonWidget(
                                  icon: 'assets/Icons/chevron.svg',
                                  svgColor: Colors.white,
                                  title: 'Continue',
                                  onPressed: !hasImages
                                      ? () {
                                          ToastService.showError(
                                            context,
                                            title: "No Images",
                                            message: "Upload an image first.",
                                          );
                                        }
                                      : () async {
                                          final result = await context.pushNamed(
                                            'iris-editor',
                                            extra: {
                                              'session': widget.session,
                                              'imageUrls': currentPaths,
                                            },
                                          );
                                          if (result is Map<String, dynamic> &&
                                              result.containsKey('returnedImages')) {
                                            // Handle return logic if needed
                                          }
                                        },
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // ✅ Global Drag Overlay (Optional but Pro UX)
            // This shows a dark tint over the WHOLE screen when dragging files over it
            if (_isDragging)
              IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_all, color: Colors.white, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          "Drop images here",
                          style: GoogleFonts.poppins(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}