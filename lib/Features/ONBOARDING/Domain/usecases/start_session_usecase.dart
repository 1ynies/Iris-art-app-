import 'package:dartz/dartz.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/respositories/onboarding_repository.dart';
import '../entities/client_session.dart';

class StartSessionUseCase {
  final OnboardingRepository repository;

  StartSessionUseCase(this.repository);

  Future<Either<Exception, ClientSession>> call(String name, String email, String country) async {
    return await repository.startSession(name: name, email: email, country: country);
  }
}