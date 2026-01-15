import 'package:dartz/dartz.dart';
import '../entities/project_details.dart';

abstract class ProjectHubRepository {
  /// Fetches the initial project data (client info, existing images)
  Future<Either<Exception, ProjectDetails>> getProjectDetails(String projectId);

  /// Uploads a new image and returns the new image URL (or ID)
  Future<Either<Exception, String>> uploadImage(String projectId, String imagePath);
}