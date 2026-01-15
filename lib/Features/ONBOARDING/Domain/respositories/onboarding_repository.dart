import 'package:dartz/dartz.dart'; // Add dartz to pubspec.yaml for Either
import '../entities/client_session.dart';

abstract class OnboardingRepository {
  Future<Either<Exception, ClientSession>> startSession({
    required String name,
    required String email,
    required String country,
  });
}