import 'package:dartz/dartz.dart';
import 'package:iris_designer/Core/Services/hive_service.dart'; // ✅ Import Hive Service
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/respositories/onboarding_repository.dart';
import 'package:uuid/uuid.dart'; // Optional: Use this for real unique IDs

class OnboardingRepositoryImpl implements OnboardingRepository {
  
  @override
  Future<Either<Exception, ClientSession>> startSession({
    required String name,
    required String email,
    required String country,
  }) async {
    try {
      // Simulate Network Delay
      await Future.delayed(const Duration(seconds: 1));

      // ✅ FIX: Use proper unique ID and initialize new fields
      final newSession = ClientSession(
        id: const Uuid().v4(), // Generates a unique string ID
        clientName: name,
        email: email,
        country: country,
        createdAt: DateTime.now(), // ✅ Required for 24h expiry
        importedPhotos: const [],  // ✅ Initialize empty list
        generatedArt: const [],    // ✅ Initialize empty list
      );

      // ✅ SAVE TO HIVE: Store locally so the History Table can see it
      await HiveService.saveSession(newSession);

      return Right(newSession);
    } catch (e) {
      return Left(Exception('Failed to start session: $e'));
    }
  }
}