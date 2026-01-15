import 'package:dartz/dartz.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/respositories/project_hub_repository.dart';
import '../entities/project_details.dart';

class LoadProjectDataUseCase {
  final ProjectHubRepository repository;

  LoadProjectDataUseCase(this.repository);

  Future<Either<Exception, ProjectDetails>> call(String projectId) async {
    return await repository.getProjectDetails(projectId);
  }
}