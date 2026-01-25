import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_event.dart';
import 'package:iris_designer/Features/EDITOR/Presentation/bloc/editor_state.dart';
import 'package:uuid/uuid.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';
import 'package:iris_designer/Features/EDITOR/Domain/usecases/save_image_progress_usecase.dart';
import 'package:iris_designer/Core/Services/photopea_service.dart'; // ✅ Import Photopea Service

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final SaveImageProgressUseCase saveProgressUseCase;
  final PhotopeaService _photopeaService = PhotopeaService(); // ✅ Singleton Access

  EditorBloc({required this.saveProgressUseCase}) : super(const EditorState()) {
    
    // -----------------------------------------------------------------
    // 1. Load Session & Initialize Engine
    // -----------------------------------------------------------------
    on<LoadEditorSession>((event, emit) async {
      final images = event.imageUrls.map((path) => 
        IrisImage(id: const Uuid().v4(), imagePath: path)
      ).toList();
      
      emit(state.copyWith(
        status: EditorStatus.loaded, 
        images: images,
        activeIndex: 0,
        currentStep: 0,
      ));

      // ✅ PHOTOPEA: Load the first image into the engine immediately
      if (images.isNotEmpty) {
        // Small delay ensures WebView is mounted before receiving commands
        await Future.delayed(const Duration(milliseconds: 500));
        await _photopeaService.loadImage(images.first.imagePath);
      }
    });

    // -----------------------------------------------------------------
    // 2. Switch Image
    // -----------------------------------------------------------------
    on<SwitchActiveImage>((event, emit) async {
      emit(state.copyWith(
        activeIndex: event.index,
        currentStep: 0, // Reset step workflow for new image
      ));

      // ✅ PHOTOPEA: Swap the active image in the engine
      if (state.images.isNotEmpty && event.index < state.images.length) {
        await _photopeaService.loadImage(state.images[event.index].imagePath);
      }
    });

    // -----------------------------------------------------------------
    // 3. Change Step (Tab Click)
    // -----------------------------------------------------------------
    on<StepChanged>((event, emit) {
      emit(state.copyWith(currentStep: event.newStep));
      // Optional: You could reset Photopea tools here if needed
    });

    // -----------------------------------------------------------------
    // 4. Color Adjustment (Real-time Slider Proxy)
    // -----------------------------------------------------------------
    // Ensure 'ColorAdjustmentChanged' is defined in your editor_event.dart
    on<ColorAdjustmentChanged>((event, emit) {
      // 1. Update UI State (so sliders persist if user switches tabs)
      emit(state.copyWith(
        brightness: event.brightness,
        contrast: event.contrast,
        saturation: event.saturation,
        hue: event.hue
      ));

      // 2. ✅ PHOTOPEA: Send command to engine
      _photopeaService.adjustColor(
        brightness: event.brightness,
        contrast: event.contrast,
        saturation: event.saturation,
        hue: event.hue
      );
    });

    // -----------------------------------------------------------------
    // 5. Flash Correction (Brush Proxy)
    // -----------------------------------------------------------------
    // Ensure 'FlashCorrectionApplied' is defined in your editor_event.dart
    on<FlashCorrectionApplied>((event, emit) {
      // ✅ PHOTOPEA: Send brush strokes to engine
      _photopeaService.correctFlashAtPoints(event.points, event.brushSize);
    });

    // -----------------------------------------------------------------
    // 6. Circling (Selection Proxy)
    // -----------------------------------------------------------------
    // Ensure 'CirclingApplied' is defined in your editor_event.dart
    on<CirclingApplied>((event, emit) {
      // ✅ PHOTOPEA: Apply crop/selection to engine
      _photopeaService.applyCircling(
        x: event.x, 
        y: event.y, 
        width: event.width, 
        height: event.height
      );
    });

    // -----------------------------------------------------------------
    // 7. Apply Current Step (Workflow Commit)
    // -----------------------------------------------------------------
    on<ApplyCurrentStep>((event, emit) {
      // Clone list to make it mutable
      List<IrisImage> updatedList = List.from(state.images);
      IrisImage currentImg = updatedList[state.activeIndex];

      // Mark current step as done in the metadata
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

    // -----------------------------------------------------------------
    // 8. Save Progress (Export)
    // -----------------------------------------------------------------
    on<SaveProgressRequested>((event, emit) async {
      emit(state.copyWith(status: EditorStatus.saving));
      
      // ✅ PHOTOPEA: Trigger the save export from the engine
      await _photopeaService.exportImage();

      // Save metadata to local DB
      final result = await saveProgressUseCase(state.images);
      
      result.fold(
        (failure) => emit(state.copyWith(status: EditorStatus.failure, errorMessage: "Save Failed")),
        (success) => emit(state.copyWith(status: EditorStatus.success)),
      );
    });
  }
}