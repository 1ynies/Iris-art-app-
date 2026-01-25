import 'package:equatable/equatable.dart';

abstract class EditorEvent extends Equatable {
  const EditorEvent();

  @override
  List<Object> get props => [];
}

// --- Session Management ---

class LoadEditorSession extends EditorEvent {
  final List<String> imageUrls;
  const LoadEditorSession(this.imageUrls);

  @override
  List<Object> get props => [imageUrls];
}

class SwitchActiveImage extends EditorEvent {
  final int index;
  const SwitchActiveImage(this.index);

  @override
  List<Object> get props => [index];
}

// --- Workflow Navigation ---

class ApplyCurrentStep extends EditorEvent {
  // BLoC knows the current state, no params needed
}

class StepChanged extends EditorEvent {
  final int newStep;
  const StepChanged(this.newStep);

  @override
  List<Object> get props => [newStep];
}

class SaveProgressRequested extends EditorEvent {}

// --- Real-Time Editing Events (Fixed: Added these classes) ---

class ColorAdjustmentChanged extends EditorEvent {
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;

  const ColorAdjustmentChanged({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.hue = 0,
  });

  @override
  List<Object> get props => [brightness, contrast, saturation, hue];
}

class FlashCorrectionApplied extends EditorEvent {
  final List<Map<String, double>> points; // List of {x, y} coordinates
  final double brushSize;

  const FlashCorrectionApplied({
    required this.points,
    required this.brushSize,
  });

  @override
  List<Object> get props => [points, brushSize];
}

class CirclingApplied extends EditorEvent {
  final double x;
  final double y;
  final double width;
  final double height;

  const CirclingApplied({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  List<Object> get props => [x, y, width, height];
}