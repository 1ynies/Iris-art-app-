import 'package:equatable/equatable.dart';

class ProjectDetails extends Equatable {
  final String projectId;
  final String clientName;
  final List<String> imageUrls; // URLs of uploaded images

  const ProjectDetails({
    required this.projectId,
    required this.clientName,
    required this.imageUrls,
  });

  // ✅ YOU NEED THIS METHOD FOR THE BLOC TO WORK
  ProjectDetails copyWith({
    String? projectId,
    String? clientName,
    List<String>? imageUrls,
  }) {
    return ProjectDetails(
      projectId: projectId ?? this.projectId,
      clientName: clientName ?? this.clientName,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  List<Object?> get props => [projectId, clientName, imageUrls];
}