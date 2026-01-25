import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- ONBOARDING IMPORTS ---
import 'package:iris_designer/Features/ONBOARDING/Data/repositories/onboarding_repository_impl.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/respositories/onboarding_repository.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/usecases/start_session_usecase.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/bloc/onboarding_bloc.dart';

// --- PROJECT HUB IMPORTS ---
import 'package:iris_designer/Features/PROJECT_HUB/Data/repositories/project_hub_repository_impl.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/respositories/project_hub_repository.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/usecases/load_project_data_usecase.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/usecases/upload_image_usecase.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';

// --- EDITOR IMPORTS (✅ ADDED) ---
import 'package:iris_designer/Features/EDITOR/Domain/usecases/save_image_progress_usecase.dart';

// Global Service Locator Instance
final sl = GetIt.instance;

Future<void> init() async {
  // 1. External Services
  await Hive.initFlutter();
  
  // Register Adapter
  if (!Hive.isAdapterRegistered(0)) {
     Hive.registerAdapter(ClientSessionAdapter()); 
  }
  
  await Hive.openBox<ClientSession>('sessions_box');

  // =========================================================
  // 🚀 FEATURE - ONBOARDING
  // =========================================================

  // Bloc
  sl.registerFactory(
    () => OnboardingBloc(
      startSessionUseCase: sl(), 
    ),
  );

  // Use Case
  sl.registerLazySingleton(() => StartSessionUseCase(sl()));

  // Repository
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(),
  );
  
  // =========================================================
  // 🚀 FEATURE - PROJECT HUB
  // =========================================================
  
  // Bloc
  sl.registerFactory(
    () => ProjectHubBloc(
      loadProjectUseCase: sl(),
      uploadImageUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoadProjectDataUseCase(sl()));
  sl.registerLazySingleton(() => UploadImageUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProjectHubRepository>(
    () => ProjectHubRepositoryImpl(),
  );

  // =========================================================
  // 🚀 FEATURE - EDITOR (✅ FIXED: ADDED THIS SECTION)
  // =========================================================
  
  // Use Case
  // Note: If SaveImageProgressUseCase requires a Repository in the future, 
  // you must register the repository first and pass it here like: 
  // sl.registerLazySingleton(() => SaveImageProgressUseCase(sl()));
  sl.registerLazySingleton(() => SaveImageProgressUseCase());
}