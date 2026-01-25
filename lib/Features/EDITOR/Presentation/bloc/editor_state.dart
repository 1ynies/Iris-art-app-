import 'package:equatable/equatable.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

enum EditorStatus { initial, loading, loaded, saving, success, failure }

class EditorState extends Equatable {
  final EditorStatus status;
  final List<IrisImage> images;
  final int activeIndex;
  final int currentStep; // 0: Circling, 1: Flash, 2: Color
  final String? errorMessage;

  // ✅ New: Color Adjustment Fields (Required for Slider persistence)
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;

  const EditorState({
    this.status = EditorStatus.initial,
    this.images = const [],
    this.activeIndex = 0,
    this.currentStep = 0,
    this.errorMessage,
    // ✅ Initialize defaults
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.hue = 0.0,
  });

  IrisImage get activeImage => images.isNotEmpty ? images[activeIndex] : const IrisImage(id: '0', imagePath: '');
  
  bool get allImagesDone => images.every((img) => img.isFullyEdited);

  EditorState copyWith({
    EditorStatus? status,
    List<IrisImage>? images,
    int? activeIndex,
    int? currentStep,
    String? errorMessage,
    // ✅ Add to copyWith
    double? brightness,
    double? contrast,
    double? saturation,
    double? hue,
  }) {
    return EditorState(
      status: status ?? this.status,
      images: images ?? this.images,
      activeIndex: activeIndex ?? this.activeIndex,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
      // ✅ Update logic
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      hue: hue ?? this.hue,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    images, 
    activeIndex, 
    currentStep, 
    errorMessage,
    // ✅ Add to props for Equatable
    brightness,
    contrast,
    saturation,
    hue,
  ];
}