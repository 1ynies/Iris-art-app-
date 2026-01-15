import 'package:dartz/dartz.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/entities/project_details.dart';
import 'package:iris_designer/Features/PROJECT_HUB/Domain/respositories/project_hub_repository.dart';

class ProjectHubRepositoryImpl implements ProjectHubRepository {
  // In a real app, you would inject a RemoteDataSource here
  // final ProjectHubRemoteDataSource remoteDataSource;

  @override
  Future<Either<Exception, ProjectDetails>> getProjectDetails(
    String projectId,
  ) async {
    try {
      // ⏳ Simulate Network Delay
      await Future.delayed(const Duration(seconds: 1));

      // 📦 Return Mock Data

      return Right(
        ProjectDetails(
          projectId: projectId,
          clientName: "Client Name",
          imageUrls: [], // <--- Start empty!
        ),
      );
    } catch (e) {
      return Left(Exception('Failed to fetch project details'));
    }
  }

  @override
  Future<Either<Exception, String>> uploadImage(
    String projectId,
    String imagePath,
  ) async {
    try {
      // ⏳ Simulate Upload Delay
      await Future.delayed(const Duration(seconds: 2));

      // Return a fake URL for the uploaded image
      return const Right('https://picsum.photos/id/100/200/200');
    } catch (e) {
      return Left(Exception('Failed to upload image'));
    }
  }
}
