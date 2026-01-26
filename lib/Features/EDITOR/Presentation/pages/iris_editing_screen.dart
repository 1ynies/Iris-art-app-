import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iris_designer/Features/EDITOR/Domain/services/color_adjustment_dart.dart';
import 'package:uuid/uuid.dart';

// Core Imports
import 'package:iris_designer/Core/Config/dependecy_injection.dart';
import 'package:iris_designer/Core/Services/hive_service.dart';
import 'package:iris_designer/Core/Services/iris_engine_service.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_custom_navbar.dart';
import 'package:iris_designer/Core/Shared/Widgets/global_submit_button_widget.dart';
import 'package:iris_designer/Core/Utils/toast_service.dart';

// Features
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';
import 'package:iris_designer/Features/EDITOR/Domain/usecases/save_image_progress_usecase.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_bloc.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/views/circling_view.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/views/color_adjustment_view.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/views/flash_correction_view.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';

import 'package:iris_designer/Features/EDITOR/Presentation/widgets/queue_image_item.dart';


class IrisEditingScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const IrisEditingScreen({super.key, required this.extra});

  @override
  State<IrisEditingScreen> createState() => _IrisEditingScreenState();
}

class _IrisEditingScreenState extends State<IrisEditingScreen> {
  bool _isProcessing = false;

  late ClientSession _session;
  List<IrisImage> _projectImages = [];
  int _selectedImageIndex = 0;
  int _currentStep = 0;

  double _outerRadiusVal = 0.5;
  double _innerRadiusVal = 0.2;
  double _ovalRatio = 1.0;
  Offset _outerCircleOffset = Offset.zero;
  Offset _innerCircleOffset = Offset.zero;
  Size? _circlingViewSize;

  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _vibrance = 0.0;
  ColorPreset? _selectedPreset;

  /// For each image index, path after flash (before color). Used by Color step Reset.
  final Map<int, String> _pathAfterFlash = {};

  @override
  void initState() {
    super.initState();
    _session = widget.extra['session'] as ClientSession;
    final urls = List<String>.from(widget.extra['imageUrls'] ?? []);

    _projectImages = urls.map((path) {
      bool isProcessed = path.contains('edited_');
      return IrisImage(
        id: const Uuid().v4(),
        imagePath: path,
        isCirclingDone: isProcessed,
        isFlashDone: isProcessed,
        isColorDone: isProcessed,
      );
    }).toList();
  }

  IrisImage get _activeImage => _projectImages[_selectedImageIndex];
  bool get _allImagesDone => _projectImages.every((img) => img.isFullyEdited);

  void _switchImage(int index) {
    setState(() {
      _selectedImageIndex = index;
      _currentStep = 0;
      _resetTools();
    });
    // Photopea is only used for flash correction; no need to load on switch.
  }

  void _removeImageFromQueue(int index) {
    if (_projectImages.length <= 1) {
      ToastService.showError(
        context,
        title: "Cannot remove",
        message: "Keep at least one image in the queue.",
      );
      return;
    }
    final img = _projectImages[index];
    final removedPath = img.originalPath;

    setState(() {
      _projectImages.removeAt(index);
      if (_selectedImageIndex >= _projectImages.length) {
        _selectedImageIndex = _projectImages.length - 1;
      } else if (index < _selectedImageIndex) {
        _selectedImageIndex--;
      }
    });

    context.read<ProjectHubBloc>().add(
      RemoveImageTriggered(imagePath: removedPath),
    );
    HiveService.removeImageFromSession(_session.id, removedPath);

  }

  void _resetTools() {
    _outerRadiusVal = 0.5;
    _innerRadiusVal = 0.2;
    _ovalRatio = 1.0;
    _outerCircleOffset = Offset.zero;
    _innerCircleOffset = Offset.zero;
    _brightness = 0.0;
    _contrast = 0.0;
    _saturation = 0.0;
    _vibrance = 0.0;
    _selectedPreset = null;
  }

  void _resetColorAdjustments() {
    setState(() {
      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;
      _vibrance = 0.0;
      _selectedPreset = null;
      final pathAfterFlash = _pathAfterFlash[_selectedImageIndex];
      if (pathAfterFlash != null) {
        _projectImages[_selectedImageIndex] = _activeImage.copyWith(
          imagePath: pathAfterFlash,
          isColorDone: false,
        );
      }
    });
  }

  void _handleEditingResult(String newPath) {
    if (!mounted) return;
    final wasFlashStep = _currentStep == 1;
    setState(() {
      _isProcessing = false;
      if (wasFlashStep) _pathAfterFlash[_selectedImageIndex] = newPath;
      IrisImage updated = _activeImage.copyWith(imagePath: newPath);
      if (_currentStep == 0) updated = updated.copyWith(isCirclingDone: true);
      if (_currentStep == 1) updated = updated.copyWith(isFlashDone: true);
      if (_currentStep == 2) updated = updated.copyWith(isColorDone: true);
      _projectImages[_selectedImageIndex] = updated;
      if (_currentStep < 2) {
        _currentStep++;
        if (_currentStep == 2) _resetTools();
      }
    });
    ToastService.showSuccess(
      context,
      title: "Progress saved",
      message: "Step applied.",
    );
  }

  Future<void> _applyCurrentStep() async {
    setState(() => _isProcessing = true);
    try {
      if (_currentStep == 0) {
        String? newPath;
        if (IrisEngineService.isCutAndWarpAvailable && _circlingViewSize != null) {
          final sz = _circlingViewSize!;
          final safeOuterR = _outerRadiusVal.clamp(0.0, 1.0);
          final maxInner = safeOuterR > 0.01 ? safeOuterR - 0.01 : safeOuterR;
          final safeInnerR = _innerRadiusVal.clamp(0.0, maxInner);
          newPath = await IrisEngineService.processCirclingWithViewParams(
            _activeImage.imagePath,
            viewW: sz.width,
            viewH: sz.height,
            outerR: safeOuterR,
            innerR: safeInnerR,
            outerDx: _outerCircleOffset.dx,
            outerDy: _outerCircleOffset.dy,
            innerDx: _innerCircleOffset.dx,
            innerDy: _innerCircleOffset.dy,
          );
        }
        if (newPath == null && IrisEngineService.isAvailable) {
          newPath = await IrisEngineService.processCircling(_activeImage.imagePath);
        }
        if (newPath != null && mounted) {
          _handleEditingResult(newPath);
        } else {
          setState(() => _isProcessing = false);
          if (mounted) {
            String message;
            if (!IrisEngineService.isAvailable) {
              message = "Iris Engine not available. Ensure iris_engine.dll is next to the exe.";
            } else if (!IrisEngineService.isOpenCvAvailable) {
              message = "Iris Engine built without OpenCV. Set OpenCV_DIR and rebuild.";
            } else if (!IrisEngineService.isCutAndWarpAvailable) {
              message = "Iris Engine DLL is out of date. Rebuild the Windows app.";
            } else if (_circlingViewSize == null) {
              message = "Layout not ready yet. Try again in a second.";
            } else {
              message = "Could not complete circling. Adjust the circles and try again.";
            }
            ToastService.showError(
              context,
              title: "Circling failed",
              message: message,
            );
          }
        }
        return;
      }

      if (_currentStep == 1) {
        final newPath = await IrisEngineService.processFlashRemoval(
          _activeImage.imagePath,
          threshold: 0.95,
          dilatePixels: 3,
        );
        if (newPath != null && mounted) {
          _handleEditingResult(newPath);
        } else {
          setState(() => _isProcessing = false);
          if (mounted) {
            ToastService.showError(
              context,
              title: "Error",
              message: IrisEngineService.isAvailable
                  ? "Flash correction failed (Iris Engine)"
                  : "Iris Engine not available. Run on Windows with iris_engine.dll.",
            );
          }
        }
        return;
      }

      if (_currentStep == 2) {
        _pathAfterFlash[_selectedImageIndex] ??= _activeImage.imagePath;
        final newPath = await IrisEngineService.processColorEffects(
          _activeImage.imagePath,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          vibrance: _vibrance,
        );
        setState(() => _isProcessing = false);
        if (newPath != null && mounted) {
          _handleEditingResult(newPath);
        } else if (mounted) {
          ToastService.showError(
            context,
            title: "Error",
            message: IrisEngineService.isAvailable
                ? "Color adjustment failed (Iris Engine)"
                : "Iris Engine not available. Run on Windows with iris_engine.dll.",
          );
        }
        return;
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ToastService.showError(context, title: "Error", message: e.toString());
      }
    }
  }

  Future<void> _navigateBack() async {
    final bool shouldLeave =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            title: const Text(
              "Unsaved Progress",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Leave without finishing?",
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Leave"),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLeave) {
      // Always pass original raw images to screen 1. Use Hive's importedPhotos
      // so that we never send edited paths when the editor was opened from screen 2.
      final rawPaths = HiveService.getSessionById(_session.id)?.importedPhotos ??
          _projectImages.map((e) => e.originalPath).toList();
      await HiveService.updateSessionImages(_session.id, rawPaths);
      if (!mounted) return;
      ToastService.showSuccess(
        context,
        title: "Progress saved",
        message: "Session updated.",
      );
      if (!mounted) return;
      context.goNamed(
        'image-prep',
        extra: {'session': _session, 'returnedImages': rawPaths},
      );
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png'],
    );
    if (result != null) {
      setState(() {
        _projectImages.add(
          IrisImage(
            id: const Uuid().v4(),
            imagePath: result.files.single.path!,
          ),
        );
      });
      ToastService.showSuccess(
        context,
        title: "Image Added",
        message: "Queue updated.",
      );
    }
  }

  void _skipCurrentStep() {
    setState(() {
      if (_currentStep == 1) {
        _pathAfterFlash[_selectedImageIndex] = _activeImage.imagePath;
        _projectImages[_selectedImageIndex] = _activeImage.copyWith(
          isFlashDone: true,
        );
      }
      if (_currentStep == 2)
        _projectImages[_selectedImageIndex] = _activeImage.copyWith(
          isColorDone: true,
        );
      if (_currentStep < 2) _currentStep++;
    });
  }

  void _resetSelection() {
    setState(() {
      _resetTools();
      final rawPath = _activeImage.originalPath;
      _projectImages[_selectedImageIndex] = _activeImage.copyWith(
        imagePath: rawPath,
        isCirclingDone: false,
        isFlashDone: false,
        isColorDone: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          EditorBloc(saveProgressUseCase: sl<SaveImageProgressUseCase>()),
      child: Scaffold(
        backgroundColor: const Color(0xFF12151B),
        appBar: CustomNavBar(
          title: "Iris Editor",
          subtitle: _session.clientName,
          onArrowPressed: _navigateBack,
          helpDialogNum: '3',
        ),
        floatingActionButton: Opacity(
          opacity: _allImagesDone ? 1.0 : 0.5,
          child: SizedBox(
            width: 250,
            child: GlobalSubmitButtonWidget(
              title: "Go create art",
              icon: 'assets/Icons/brush.svg',
              svgColor: Colors.white,
              onPressed: () async {
                if (_allImagesDone) {
                  final paths = _projectImages.map((e) => e.imagePath).toList();
                  await HiveService.updateSessionGeneratedArt(
                    _session.id,
                    paths,
                  );
                  if (!mounted) return;
                  ToastService.showSuccess(
                    context,
                    title: "Progress saved",
                    message: "Ready for art studio.",
                  );
                  if (!mounted) return;
                  context.goNamed(
                    'image-prep-2',
                    extra: {'session': _session, 'imageUrls': paths},
                  );
                }
              },
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(color: const Color(0xFF12151B)),
            ),
            Positioned.fill(
              child: Container(
                color: const Color(0xFF12151B),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: _buildEditorView(),
                                    ),
                                  ),
                                ),
                                _buildBottomControls(),
                              ],
                            ),
                          ),
                          _buildQueue(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
          outerCenterOffset: _outerCircleOffset,
          innerCenterOffset: _innerCircleOffset,
          onOuterPan: (dx, dy) =>
              setState(() => _outerCircleOffset += Offset(dx, dy)),
          onInnerPan: (dx, dy) =>
              setState(() => _innerCircleOffset += Offset(dx, dy)),
          onOuterRadiusChange: (v) => setState(() => _outerRadiusVal = v),
          onInnerRadiusChange: (v) =>
              setState(() => _innerRadiusVal = v.clamp(0.0, _outerRadiusVal)),
          onOvalRatioChange: (ratio) => setState(() => _ovalRatio = ratio),
          onLayoutSize: (s) => WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _circlingViewSize = s);
          }),
        );
      case 1:
        return FlashCorrectionView(
          activeImage: _activeImage,
          onBrushStroke: null,
        );
      case 2:
        return ColorAdjustmentView(
          activeImage: _activeImage,
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          vibrance: _vibrance,
          selectedPreset: _selectedPreset,
          onAdjustmentChanged: (b, c, s, v) => setState(() {
            _brightness = b;
            _contrast = c;
            _saturation = s;
            _vibrance = v;
          }),
          onPresetSelected: (p) => setState(() {
            _selectedPreset = p;
            if (p != null) {
              _brightness = p.brightness;
              _contrast = p.contrast;
              _saturation = p.saturation;
              _vibrance = p.vibrance;
            }
          }),
          onReset: _resetColorAdjustments,
        );
      default:
        return const SizedBox();
    }
  }

  Container _buildQueue(BuildContext context) {
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
                        child: const Center(
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                final img = _projectImages[index];
                return QueueImageItem(
                  // FIXED: Ensure this matches the public class name
                  // Added key for better list performance
                  img: img,
                  isSelected: index == _selectedImageIndex,
                  isDone: img.isFullyEdited,
                  onTap: () => _switchImage(index),
                  onRemove: () => _removeImageFromQueue(index),
                );
              },
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
    final bool isActive = _currentStep == index;
    final bool isDone = index == 0
        ? _activeImage.isCirclingDone
        : index == 1
        ? _activeImage.isFlashDone
        : _activeImage.isColorDone;
    final bool isLocked = index == 1
        ? !_activeImage.isCirclingDone
        : index == 2
        ? !_activeImage.isFlashDone
        : false;
    final Color color = isActive
        ? Colors.blueAccent
        : isDone
        ? Colors.green
        : isLocked
        ? Colors.white12
        : Colors.grey;

    return InkWell(
      onTap: !isLocked ? () => setState(() => _currentStep = index) : null,
      child: Column(
        children: [
          Row(
            children: [
              isLocked
                  ? Icon(Icons.lock, color: color, size: 15)
                  : SvgPicture.asset(
                      iconpath,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                      width: 15,
                      height: 15,
                    ),
              const Gap(8),
              Text(
                title,
                style: TextStyle(
                  color: color,
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
                showReset: true,
                onReset: () => setState(() => _ovalRatio = 1.0),
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

          if (_currentStep > 0) ...[
            const Spacer(),
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
            onPressed: _isProcessing ? null : _applyCurrentStep,
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
    required void Function(double) onChanged,
    String? overrideDisplay,
    bool showReset = false,
    VoidCallback? onReset,
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
              Row(
                children: [
                  Text(
                    overrideDisplay ?? "${(value * 100).toInt()}%",
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                    ),
                  ),
                  if (showReset && onReset != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onReset,
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
