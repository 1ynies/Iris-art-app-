import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iris_designer/Features/ONBOARDING/Data/repositories/onboarding_repository_impl.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/respositories/onboarding_repository.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/usecases/start_session_usecase.dart';
import 'package:iris_designer/Features/ONBOARDING/Presentation/bloc/onboarding_bloc.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Data/repositories/project_hub_repository_impl.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/respositories/project_hub_repository.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/usecases/load_project_data_usecase.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/usecases/upload_image_usecase.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Presentation/bloc/project_hub_bloc.dart';

// Global Service Locator Instance





// Import other features (Project Hub, etc.)
// ...

final sl = GetIt.instance;

Future<void> init() async {
  // 1. External Services
  await Hive.initFlutter();
  
  // Register Adapter (Like in Vaccigo)
  if (!Hive.isAdapterRegistered(0)) {
     Hive.registerAdapter(ClientSessionAdapter()); 
  }
  
  await Hive.openBox<ClientSession>('sessions_box');

  // =========================================================
  // 🚀 FEATURE - ONBOARDING
  // =========================================================

  // Bloc (Factory - New instance per UI request)
  sl.registerFactory(
    () => OnboardingBloc(
      startSessionUseCase: sl(), 
    ),
  );

  // Use Case
  sl.registerLazySingleton(() => StartSessionUseCase(sl()));

  // Repository
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(
      // Inject Hive Box if needed, or other data sources
    ),
  );
  
  // =========================================================
  // 🚀 FEATURE - PROJECT HUB (Add similar setup)
  // =========================================================
  // ..
  // 
  sl.registerFactory(
    () => ProjectHubBloc(
      loadProjectUseCase: sl(),
      uploadImageUseCase: sl(),
    ),
  );

  // 2. Use Cases
  sl.registerLazySingleton(() => LoadProjectDataUseCase(sl()));
  sl.registerLazySingleton(() => UploadImageUseCase(sl()));

  // 3. Repository
  sl.registerLazySingleton<ProjectHubRepository>(
    () => ProjectHubRepositoryImpl(),
  );
}