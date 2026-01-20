import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:iris_designer/Core/Services/hive_service.dart'; // ✅ Import HiveService
import 'package:iris_designer/Features/PROJECT_HUB/Domain/entities/project_details.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/usecases/load_project_data_usecase.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/usecases/upload_image_usecase.dart';

// --- EVENTS ---
abstract class ProjectHubEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadProjectData extends ProjectHubEvent {
  final String projectId;
  LoadProjectData(this.projectId);

  @override
  List<Object> get props => [projectId];
}

class UploadImageTriggered extends ProjectHubEvent {
  final String projectId;
  final String imagePath;

  UploadImageTriggered({required this.projectId, required this.imagePath});

  @override
  List<Object> get props => [projectId, imagePath];
}

// ... existing imports

class RemoveImageTriggered extends ProjectHubEvent {
  final String imagePath;
  
   RemoveImageTriggered({required this.imagePath});

  @override
  List<Object> get props => [imagePath];
}

// --- STATES ---
abstract class ProjectHubState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProjectHubLoading extends ProjectHubState {}

class ProjectHubLoaded extends ProjectHubState {
  final ProjectDetails project;

  // Adding a timestamp ensures state is always seen as "new" when we emit it,
  // fixing issues where Lists don't trigger rebuilds.
  final int _timestamp;

  ProjectHubLoaded(this.project)
    : _timestamp = DateTime.now().millisecondsSinceEpoch;

  ProjectHubLoaded copyWith({ProjectDetails? project}) {
    return ProjectHubLoaded(project ?? this.project);
  }

  @override
  List<Object?> get props => [project, _timestamp];
}

class ProjectHubError extends ProjectHubState {
  final String message;
  ProjectHubError(this.message);

  @override
  List<Object> get props => [message];
}

// --- BLOC ---
class ProjectHubBloc extends Bloc<ProjectHubEvent, ProjectHubState> {
  final LoadProjectDataUseCase loadProjectUseCase;
  final UploadImageUseCase uploadImageUseCase;

  ProjectHubBloc({
    required this.loadProjectUseCase,
    required this.uploadImageUseCase,
  }) : super(ProjectHubLoading()) {
    // -----------------------------------------------------------------
    // EVENT: Load Data
    // -----------------------------------------------------------------
    on<LoadProjectData>((event, emit) async {
      emit(ProjectHubLoading());

      // Even if loading fails or returns nothing, we need to START with a valid Loaded state
      // so the user can start adding images.
      final emptyProject = ProjectDetails(
        projectId: event.projectId,
        clientName: 'Client', // Or fetch name
        imageUrls: [],
      );

      // If you have real fetching logic, use it here.
      // But ensure you emit ProjectHubLoaded(emptyProject) if fetch fails or is empty.
      emit(ProjectHubLoaded(emptyProject));
    });

    // -----------------------------------------------------------------
    // EVENT: Upload Image
    // -----------------------------------------------------------------
    on<UploadImageTriggered>((event, emit) async {
      if (state is ProjectHubLoaded) {
        final currentState = state as ProjectHubLoaded;

        debugPrint("📸 BLOC: Upload Triggered for ${event.imagePath}");

        // OPTIMISTIC UPDATE:
        // We assume success and update the UI immediately with the local path.
        // This ensures the user sees the image instantly.

        final updatedImages = List<String>.from(currentState.project.imageUrls)
          ..add(event.imagePath);

        // Reconstruct the project with the new image list
        // (Ensure ProjectDetails matches your entity definition)
        final updatedProject = ProjectDetails(
          projectId: currentState.project.projectId,
          clientName: currentState.project.clientName,
          imageUrls: updatedImages,
        );

        // Emit the state with the LOCAL file path immediately
        emit(currentState.copyWith(project: updatedProject));

        // ✅ SAVE TO HIVE: Update session with new image
        await HiveService.addImageToSession(event.projectId, event.imagePath);
        debugPrint("💾 BLOC: Image saved to Hive for session ${event.projectId}");

        // Now perform the actual upload in the background
        final result = await uploadImageUseCase(
          event.projectId,
          event.imagePath,
        );

        result.fold(
          (failure) {
            debugPrint("❌ BLOC: Upload Failed: ${failure.toString()}");
            // Optional: If upload fails, you might want to remove the image
            // from the list here (Rollback), or show a SnackBar.
          },
          (remoteUrl) {
            debugPrint("✅ BLOC: Upload Success: $remoteUrl");
            // Note: Since we already added the local path, we might not need
            // to replace it with the remote URL immediately unless you want to.
          },
        );
      } else {
        debugPrint("⚠️ BLOC: Cannot upload, state is not Loaded");
      }
    });

    // -----------------------------------------------------------------
    // EVENT: Remove Image
    // -----------------------------------------------------------------
    on<RemoveImageTriggered>((event, emit) async {
      if (state is ProjectHubLoaded) {
        final currentState = state as ProjectHubLoaded;
        
        // 1. Create a copy of the list and remove the specific path
        final updatedImages = List<String>.from(currentState.project.imageUrls)
          ..remove(event.imagePath);
        
        // 2. Update Project Object
        final updatedProject = ProjectDetails(
          projectId: currentState.project.projectId,
          clientName: currentState.project.clientName,
          imageUrls: updatedImages,
        );
        
        // 3. Emit new state
        emit(currentState.copyWith(project: updatedProject));

        // ✅ SAVE TO HIVE: Remove image from session
        await HiveService.removeImageFromSession(
          currentState.project.projectId, 
          event.imagePath
        );
        debugPrint("💾 BLOC: Image removed from Hive for session ${currentState.project.projectId}");
      }
    });
  }
}
