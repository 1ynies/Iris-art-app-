import 'dart:async';
import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Config/Theme.dart';
import 'package:iris_designer/Core/Services/hive_service.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_custom_navbar.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_submit_button_widget.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/views/circling_view.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/views/color_adjustment_view.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/views/flash_correction_view.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class IrisEditingScreen extends StatefulWidget {
  final ClientSession session;
  final List<String> imageUrls;

  const IrisEditingScreen({
    super.key,
    required this.imageUrls,
    required this.session,
  });

  @override
  State<IrisEditingScreen> createState() => _IrisEditingScreenState();
}

class _IrisEditingScreenState extends State<IrisEditingScreen> {
  late List<IrisImage> _projectImages;
  int _selectedImageIndex = 0;
  int _currentStep = 0;

  double _outerRadiusVal = 0.5;
  double _innerRadiusVal = 0.2;
  double _ovalRatio = 1.0;
  Offset _circleOffset = Offset.zero;

  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  Color? _tintColor;

  @override
  void initState() {
    super.initState();
    _projectImages = widget.imageUrls.map((path) {
      bool isProcessed =
          path.contains('cropped_') || path.contains('flash_corrected');
      return IrisImage(
        id: UniqueKey().toString(),
        imagePath: path,
        isCirclingDone: isProcessed,
        isFlashDone: isProcessed,
        isColorDone: isProcessed,
      );
    }).toList();
  }

  Future<void> _navigateBack() async {
    final bool shouldLeave =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1F2937),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Unsaved Progress",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                "Your progress on this page will be dismissed if you go back.\nAre you sure you want to leave?",
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Leave"),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldLeave) {
      context.goNamed(
        'image-prep',
        extra: {'session': widget.session, 'returnedImages': widget.imageUrls},
      );
    }
  }

  // ✅ UPDATED: High Quality Crop
  Future<void> _cropAndSaveIris() async {
    try {
      final Completer<ui.Image> completer = Completer();
      final ImageProvider provider = FileImage(File(_activeImage.imagePath));

      provider
          .resolve(const ImageConfiguration())
          .addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              completer.complete(info.image);
            }),
          );

      final ui.Image image = await completer.future;

      // ✅ Use Actual Image Dimensions (e.g., 2000x2000)
      final double width = image.width.toDouble();
      final double height = image.height.toDouble();

      final Offset center = Offset(
        (width / 2) + ((width / 2) * _circleOffset.dx),
        (height / 2) + ((height / 2) * _circleOffset.dy),
      );

      final double shortestSide = width < height ? width : height;
      final double baseRadius = shortestSide / 2;

      final double outerWidth = baseRadius * _outerRadiusVal * 2;
      final double outerHeight = outerWidth * _ovalRatio;

      final double innerWidth = baseRadius * _innerRadiusVal * 2;
      final double innerHeight = innerWidth;

      final Rect outerRect = Rect.fromCenter(
        center: center,
        width: outerWidth,
        height: outerHeight,
      );
      final Rect innerRect = Rect.fromCenter(
        center: center,
        width: innerWidth,
        height: innerHeight,
      );

      // ✅ Ensure crop size is sufficient for high quality
      final double cropSize = outerWidth > outerHeight
          ? outerWidth
          : outerHeight;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      final double shiftX = (cropSize / 2) - center.dx;
      final double shiftY = (cropSize / 2) - center.dy;
      canvas.translate(shiftX, shiftY);

      Path maskPath = Path()
        ..addOval(outerRect)
        ..addOval(innerRect)
        ..fillType = PathFillType.evenOdd;

      canvas.clipPath(maskPath);
      canvas.drawImage(image, Offset.zero, Paint());

      final ui.Picture picture = recorder.endRecording();

      // ✅ Save at Full Resolution
      final ui.Image processedImage = await picture.toImage(
        cropSize.toInt(),
        cropSize.toInt(),
      );
      final ByteData? pngBytes = await processedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (pngBytes != null) {
        final directory = await getTemporaryDirectory();
        final String newPath =
            '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
        final File newFile = File(newPath);
        await newFile.writeAsBytes(pngBytes.buffer.asUint8List());

        setState(() {
          IrisImage updatedImg = _activeImage.copyWith(
            imagePath: newPath,
            isCirclingDone: true,
          );
          _projectImages[_selectedImageIndex] = updatedImg;
          _currentStep++;
        });

        ToastService.showSuccess(
          context,
          title: "Success",
          message: "Iris extracted (Full Quality)",
        );
      }
    } catch (e) {
      debugPrint("Error cropping: $e");
    }
  }

  void _resetSelection() {
    setState(() {
      final originalPath = widget.imageUrls[_selectedImageIndex];
      _projectImages[_selectedImageIndex] = _projectImages[_selectedImageIndex]
          .copyWith(imagePath: originalPath, isCirclingDone: false);
      _outerRadiusVal = 0.5;
      _innerRadiusVal = 0.2;
      _ovalRatio = 1.0;
      _circleOffset = Offset.zero;

      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;

      ToastService.showSuccess(
        context,
        title: "Reset",
        message: "Selection reverted.",
      );
    });
  }

  IrisImage get _activeImage => _projectImages[_selectedImageIndex];
  bool get _allImagesDone => _projectImages.every((img) => img.isFullyEdited);

  void _switchImage(int index) {
    setState(() {
      _selectedImageIndex = index;
      _currentStep = 0;
      _outerRadiusVal = 0.5;
      _innerRadiusVal = 0.2;
      _ovalRatio = 1.0;
      _circleOffset = Offset.zero;
      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;
    });
  }

  void _applyCurrentStep() async {
    if (_currentStep == 0) {
      await _cropAndSaveIris();
    } else {
      setState(() {
        if (_currentStep == 1) {
          IrisImage updated = _activeImage.copyWith(isFlashDone: true);
          _projectImages[_selectedImageIndex] = updated;
        } else if (_currentStep == 2) {
          IrisImage updated = _activeImage.copyWith(isColorDone: true);
          _projectImages[_selectedImageIndex] = updated;
        }
        if (_currentStep < 2) _currentStep++;
      });
      ToastService.showSuccess(
        context,
        title: "Saved",
        message: "Changes applied.",
      );
    }
  }

  void _skipCurrentStep() {
    setState(() {
      if (_currentStep == 1) {
        IrisImage updated = _activeImage.copyWith(isFlashDone: true);
        _projectImages[_selectedImageIndex] = updated;
        _currentStep++;
        ToastService.showSuccess(
          context,
          title: "Skipped",
          message: "Flash correction skipped.",
        );
      } else if (_currentStep == 2) {
        IrisImage updated = _activeImage.copyWith(isColorDone: true);
        _projectImages[_selectedImageIndex] = updated;
        ToastService.showSuccess(
          context,
          title: "Skipped",
          message: "Color adjustment skipped.",
        );
      }
    });
  }

  Future<void> _pickImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final String filePath = result.files.single.path!;
      if (_projectImages.length >= 6) {
        if (mounted)
          ToastService.showError(
            context,
            title: "Limit Reached",
            message: "Max 6 images.",
          );
        return;
      }
      if (mounted) {
        setState(() {
          _projectImages.add(
            IrisImage(id: UniqueKey().toString(), imagePath: filePath),
          );
        });
        context.read<ProjectHubBloc>().add(
          UploadImageTriggered(
            projectId: widget.session.id,
            imagePath: filePath,
          ),
        );
        ToastService.showSuccess(
          context,
          title: "Image Added",
          message: "New iris added to queue.",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12151B),
      appBar: CustomNavBar(
        title: "Iris Editor ",
        subtitle: widget.session.clientName,
        onArrowPressed: _navigateBack,
        helpDialogNum: '3',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Opacity(
        opacity: _allImagesDone ? 1.0 : 0.5,
        child: SizedBox(
          width: 250,
          child: GlobalSubmitButtonWidget(
            title: "Go create art",
            icon: 'assets/Icons/brush.svg',
            svgColor: Colors.white,
            onPressed: () async {
              if (!_allImagesDone) {
                ToastService.showError(
                  context,
                  title: "Pending Images",
                  message:
                      "Please finish editing all images in the queue first.",
                );
              } else {
                final currentPaths = _projectImages
                    .map((e) => e.imagePath)
                    .toList();
                
                // ✅ Save edited images to generatedArt in Hive
                await HiveService.updateSessionGeneratedArt(
                  widget.session.id,
                  currentPaths,
                );
                debugPrint("💾 EDITOR: Saved ${currentPaths.length} edited images to Hive generatedArt");
                
                context.go(
                  '/image-prep-2',
                  extra: {'session': widget.session, 'imageUrls': currentPaths},
                );
              }
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildStepHeader(),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1F26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: _buildEditorView(),
                        ),
                      ),
                      _buildBottomControls(),
                    ],
                  ),
                ),
                _buildqueue(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorView() {
    switch (_currentStep) {
      case 0:
        return CirclingView(
          activeImage: _activeImage,
          outerRadius: _outerRadiusVal,
          innerRadius: _innerRadiusVal,
          ovalRatio: _ovalRatio,
          centerOffset: _circleOffset,
          onPanUpdate: (delta) => setState(() => _circleOffset += delta),
          onRadiusChange: (newRadius) =>
              setState(() => _outerRadiusVal = newRadius),
        );
      case 1:
        return FlashCorrectionView(
          activeImage: _activeImage,
          onImageUpdated: (newPath) {
            setState(() {
              IrisImage updated = _activeImage.copyWith(
                imagePath: newPath,
                isFlashDone: true,
              );
              _projectImages[_selectedImageIndex] = updated;
            });
          },
        );
      case 2:
        return ColorAdjustmentView(
          activeImage: _activeImage,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          tintColor: _tintColor,
          onAdjustmentChanged: (b, c, s, t) => setState(() {
            _brightness = b;
            _contrast = c;
            _saturation = s;
            _tintColor = t;
          }),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF15191F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep == 0) ...[
            Expanded(
              child: _buildSimpleSlider(
                label: "Outer",
                value: _outerRadiusVal,
                onChanged: (val) => setState(() => _outerRadiusVal = val),
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildSimpleSlider(
                label: "Inner",
                value: _innerRadiusVal,
                onChanged: (val) => setState(() {
                  if (val < _outerRadiusVal) _innerRadiusVal = val;
                }),
              ),
            ),
            const Gap(16),
            Expanded(
              child: _buildSimpleSlider(
                label: "Shape",
                value: (_ovalRatio - 0.5),
                overrideDisplay: _ovalRatio == 1.0 ? "Circle" : "Oval",
                onChanged: (val) => setState(() => _ovalRatio = 0.5 + val),
              ),
            ),
            const Gap(16),
            TextButton.icon(
              onPressed: _resetSelection,
              icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
              label: const Text("Reset", style: TextStyle(color: Colors.grey)),
            ),
            const Gap(16),
          ],
          if (_currentStep > 0) const Spacer(),
          if (_currentStep > 0) ...[
            TextButton(
              onPressed: _skipCurrentStep,
              child: const Text(
                "Skip",
                style: TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Gap(16),
          ],
          ElevatedButton.icon(
            onPressed: _applyCurrentStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            icon: const Icon(Icons.check),
            label: Text(_currentStep == 0 ? "Cut & Apply" : "Apply Changes"),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSlider({
    required String label,
    required double value,
    required Function(double) onChanged,
    String? overrideDisplay,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3441),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                overrideDisplay ?? "${(value * 100).toInt()}%",
                style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
              activeColor: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _buildStepItem(0, "Circling", 'assets/Icons/view_finder_solid.svg'),
          const Gap(32),
          _buildStepItem(1, "Flash Correction", 'assets/Icons/flash_solid.svg'),
          const Gap(32),
          _buildStepItem(
            2,
            "Color Adjustment",
            'assets/Icons/color_swatch_solid.svg',
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int index, String title, String iconpath) {
    bool isActive = _currentStep == index;
    bool isDone = false;
    if (index == 0) isDone = _activeImage.isCirclingDone;
    if (index == 1) isDone = _activeImage.isFlashDone;
    if (index == 2) isDone = _activeImage.isColorDone;
    bool isAccessible =
        index == 0 ||
        (index == 1 && _activeImage.isCirclingDone) ||
        (index == 2 && _activeImage.isFlashDone) ||
        isDone;
    Color color = isActive
        ? Colors.blueAccent
        : (isAccessible ? Colors.grey : Colors.white12);
    return InkWell(
      onTap: isAccessible ? () => setState(() => _currentStep = index) : null,
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconpath,
                color: isActive ? Colors.blueAccent : color,
                width: isActive ? 20 : 15,
                height: isActive ? 20 : 15,
              ),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const Gap(8),
          Container(
            height: 2,
            width: 200,
            color: isActive ? Colors.blueAccent : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Container _buildqueue() {
    return Container(
      width: 280,
      color: const Color(0xFF181E28),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "QUEUE",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                "${_projectImages.where((i) => i.isFullyEdited).length}/${_projectImages.length} done",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: ListView.separated(
              itemCount: _projectImages.length + 1,
              separatorBuilder: (_, __) => const Gap(12),
              itemBuilder: (context, index) {
                if (index == _projectImages.length) {
                  return InkWell(
                    onTap: () => _pickImage(context),
                    borderRadius: BorderRadius.circular(12),
                    child: DottedBorder(
                      color: const Color(0xFF687890),
                      strokeWidth: 2,
                      dashPattern: const [8, 4],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
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
                              child: const Icon(
                                Icons.cloud_upload_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final img = _projectImages[index];
                final isSelected = index == _selectedImageIndex;
                final isDone = img.isFullyEdited;
                Color borderColor = isSelected
                    ? Colors.blueAccent
                    : (isDone ? Colors.green : Colors.transparent);
                Color badgeColor = isSelected
                    ? Colors.blueAccent
                    : (isDone ? Colors.green : Colors.grey.withOpacity(0.8));
                String badgeText = isSelected
                    ? "EDITING"
                    : (isDone ? "DONE" : "PENDING");
                return GestureDetector(
                  onTap: () => _switchImage(index),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: (isSelected || isDone) ? 2 : 0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2A3441),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ColorFiltered(
                            colorFilter: (!isSelected && !isDone)
                                ? const ColorFilter.mode(
                                    Colors.black54,
                                    BlendMode.darken,
                                  )
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  ),
                            child: Image.file(
                              File(img.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
