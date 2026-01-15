// part of 'editor_bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

enum EditorStatus { initial, loading, loaded, saving, success, failure }

class EditorState extends Equatable {
  final EditorStatus status;
  final List<IrisImage> images;
  final int activeIndex;
  final int currentStep; // 0: Circling, 1: Flash, 2: Color
  final String? errorMessage;

  const EditorState({
    this.status = EditorStatus.initial,
    this.images = const [],
    this.activeIndex = 0,
    this.currentStep = 0,
    this.errorMessage,
  });

  IrisImage get activeImage => images.isNotEmpty ? images[activeIndex] : const IrisImage(id: '0', imagePath: '');
  
  bool get allImagesDone => images.every((img) => img.isFullyEdited);

  EditorState copyWith({
    EditorStatus? status,
    List<IrisImage>? images,
    int? activeIndex,
    int? currentStep,
    String? errorMessage,
  }) {
    return EditorState(
      status: status ?? this.status,
      images: images ?? this.images,
      activeIndex: activeIndex ?? this.activeIndex,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, images, activeIndex, currentStep, errorMessage];
}