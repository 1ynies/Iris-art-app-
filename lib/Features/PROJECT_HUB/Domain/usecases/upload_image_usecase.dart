import 'package:dartz/dartz.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/respositories/project_hub_repository.dart';

class UploadImageUseCase {
  final ProjectHubRepository repository;

  UploadImageUseCase(this.repository);

  Future<Either<Exception, String>> call(String projectId, String imagePath) async {
    return await repository.uploadImage(projectId, imagePath);
  }
}