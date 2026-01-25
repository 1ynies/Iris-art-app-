import 'package:equatable/equatable.dart';

class IrisImage extends Equatable {
  final String id;
  final String imagePath;
  /// Unedited / original path. When edits are applied, [imagePath] becomes the
  /// temp edited file; [originalPath] stays the raw image for returning to prep 1.
  final String originalPath;
  final bool isCirclingDone;
  final bool isFlashDone;
  final bool isColorDone;

  const IrisImage({
    required this.id,
    required this.imagePath,
    String? originalPath,
    this.isCirclingDone = false,
    this.isFlashDone = false,
    this.isColorDone = false,
  }) : originalPath = originalPath ?? imagePath;

  bool get isFullyEdited => isCirclingDone && isFlashDone && isColorDone;

  IrisImage copyWith({
    String? id,
    String? imagePath,
    String? originalPath,
    bool? isCirclingDone,
    bool? isFlashDone,
    bool? isColorDone,
  }) {
    return IrisImage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      originalPath: originalPath ?? this.originalPath,
      isCirclingDone: isCirclingDone ?? this.isCirclingDone,
      isFlashDone: isFlashDone ?? this.isFlashDone,
      isColorDone: isColorDone ?? this.isColorDone,
    );
  }

  @override
  List<Object?> get props => [id, imagePath, originalPath, isCirclingDone, isFlashDone, isColorDone];
}