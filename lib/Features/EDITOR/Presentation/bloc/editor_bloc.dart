import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_event.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_state.dart';
import 'package:uuid/uuid.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';
import 'package:iris_designer/Features/EDITOR/Domain/usecases/save_image_progress_usecase.dart';

// part 'editor_event.dart';
// part 'editor_state.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final SaveImageProgressUseCase saveProgressUseCase;

  EditorBloc({required this.saveProgressUseCase}) : super(const EditorState()) {
    
    // 1. Load Session
    on<LoadEditorSession>((event, emit) {
      final images = event.imageUrls.map((path) => 
        IrisImage(id: const Uuid().v4(), imagePath: path)
      ).toList();
      
      emit(state.copyWith(
        status: EditorStatus.loaded, 
        images: images,
        activeIndex: 0,
        currentStep: 0,
      ));
    });

    // 2. Switch Image
    on<SwitchActiveImage>((event, emit) {
      emit(state.copyWith(
        activeIndex: event.index,
        currentStep: 0, // Reset step when switching image
      ));
    });

    // 3. Change Step (Tab Click)
    on<StepChanged>((event, emit) {
      emit(state.copyWith(currentStep: event.newStep));
    });

    // 4. Apply Current Step (Button Click)
    on<ApplyCurrentStep>((event, emit) {
      // Clone list to make it mutable
      List<IrisImage> updatedList = List.from(state.images);
      IrisImage currentImg = updatedList[state.activeIndex];

      // Mark current step as done
      IrisImage updatedImg;
      if (state.currentStep == 0) {
        updatedImg = currentImg.copyWith(isCirclingDone: true);
      } else if (state.currentStep == 1) {
        updatedImg = currentImg.copyWith(isFlashDone: true);
      } else {
        updatedImg = currentImg.copyWith(isColorDone: true);
      }
      
      updatedList[state.activeIndex] = updatedImg;

      // Auto-advance logic
      int nextStep = state.currentStep;
      if (state.currentStep < 2) {
        nextStep++;
      }

      emit(state.copyWith(
        images: updatedList,
        currentStep: nextStep,
        status: EditorStatus.loaded, // Ensure UI stays responsive
      ));
    });

    // 5. Save Progress
    on<SaveProgressRequested>((event, emit) async {
      emit(state.copyWith(status: EditorStatus.saving));
      final result = await saveProgressUseCase(state.images);
      
      result.fold(
        (failure) => emit(state.copyWith(status: EditorStatus.failure, errorMessage: "Save Failed")),
        (success) => emit(state.copyWith(status: EditorStatus.success)),
      );
    });
  }
}