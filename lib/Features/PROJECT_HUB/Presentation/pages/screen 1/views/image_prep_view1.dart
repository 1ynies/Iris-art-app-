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
  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    // 1. Load basic project data
    context.read<ProjectHubBloc>().add(LoadProjectData(widget.session.id));

    // 2. If we have returned images (Raw originals from editor cancel), ensure they are in BLoC
    if (widget.returnedImages != null && widget.returnedImages!.isNotEmpty) {
      for (var path in widget.returnedImages!) {
        // Ensure we re-add them (Bloc should handle duplicates logic if needed)
        context.read<ProjectHubBloc>().add(
          UploadImageTriggered(projectId: widget.session.id, imagePath: path),
        );
      }
    }
  }

  // 🛠️ Updated Helper function for Multi-Selection
  Future<void> _pickImage(BuildContext context) async {
    // 1. Get current state to determine remaining slots
    final state = context.read<ProjectHubBloc>().state;
    List<String> currentImages = [];
    
    if (state is ProjectHubLoaded) {
      currentImages = state.project.imageUrls;
    }

    // Quick check before opening picker
    if (currentImages.length >= 6) {
      ToastService.showError(
        context,
        title: "Limit Reached",
        message: "You can only upload a maximum of 6 images.",
      );
      return;
    }

    // 2. Open Picker with allowMultiple: true
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: true, // ✅ Enabled Multi-Selection
    );

    if (result != null) {
      int addedCount = 0;
      bool limitReached = false;
      bool duplicateFound = false;

      // 3. Iterate through selected files
      for (var file in result.files) {
        if (file.path == null) continue;

        // Check if we hit the limit during this loop
        if ((currentImages.length + addedCount) >= 6) {
          limitReached = true;
          break; // 🛑 Stop adding more
        }

        // Check duplicates locally before adding event
        if (currentImages.contains(file.path!)) {
          duplicateFound = true;
          continue; 
        }

        // Add to Bloc
        if (context.mounted) {
          context.read<ProjectHubBloc>().add(
            UploadImageTriggered(
              projectId: widget.session.id,
              imagePath: file.path!,
            ),
          );
          addedCount++;
        }
      }

      // 4. Show Feedback
      if (context.mounted) {
        if (limitReached) {
          ToastService.showError(
            context,
            title: "Limit Reached",
            message: "Only the first ${6 - currentImages.length} images were added. Max 6 allowed.",
          );
        } else if (addedCount > 1) {
          ToastService.showSuccess(
            context,
            title: "Images Added",
            message: "$addedCount new images uploaded.",
          );
        }else if (addedCount == 1) {
          ToastService.showSuccess(
            context,
            title: "Image Added",
            message: "$addedCount new image uploaded.",
          );
        } else if (duplicateFound && addedCount == 0) {
          ToastService.showError(
            context,
            title: "Duplicate Images",
            message: "Selected images are already in the project.",
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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

              // ✅ WRAPPED CONTENT IN BLOC BUILDER
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
                      // --- Iris Images Section Header ---
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
                          // Add More Button
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

                      // --- Open Image Picker Button ---
                      if (!hasImages)
                        InkWell(
                          onTap: () => _pickImage(context),
                          child: DottedBorder(
                            color: const Color(0xFF687890),
                            strokeWidth: 2,
                            dashPattern: const [8, 4],
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(12),
                            child: SizedBox(
                              height: 250,
                              width: double.infinity,
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
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xFF94A3B8),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  const Gap(8),
                                  Text(
                                    'Click to upload images',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // --- Image Grid ---
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
                  int imageCount = 0;
                  if (state is ProjectHubLoaded) {
                    imageCount = state.project.imageUrls.length;
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$imageCount images uploaded',
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
                                      final returnedPaths =
                                          result['returnedImages'] as List<String>;
                                      print("Returned with ${returnedPaths.length} images");
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
    );
  }
}