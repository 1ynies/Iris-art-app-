

import 'package:equatable/equatable.dart';

// part of 'editor_bloc.dart';
abstract class EditorEvent extends Equatable {
  const EditorEvent();
  @override
  List<Object> get props => [];
}

class LoadEditorSession extends EditorEvent {
  final List<String> imageUrls;
  const LoadEditorSession(this.imageUrls);
}

class SwitchActiveImage extends EditorEvent {
  final int index;
  const SwitchActiveImage(this.index);
}

class ApplyCurrentStep extends EditorEvent {
  // No params needed, BLoC knows current image & step
}

class StepChanged extends EditorEvent {
  final int newStep;
  const StepChanged(this.newStep);
}

class SaveProgressRequested extends EditorEvent {}