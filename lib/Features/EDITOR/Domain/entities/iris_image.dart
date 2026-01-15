import 'package:equatable/equatable.dart';

class IrisImage extends Equatable {
  final String id;
  final String imagePath;
  final bool isCirclingDone;
  final bool isFlashDone;
  final bool isColorDone;

  const IrisImage({
    required this.id,
    required this.imagePath,
    this.isCirclingDone = false,
    this.isFlashDone = false,
    this.isColorDone = false,
  });

  bool get isFullyEdited => isCirclingDone && isFlashDone && isColorDone;

  IrisImage copyWith({
    String? id,
    String? imagePath,
    bool? isCirclingDone,
    bool? isFlashDone,
    bool? isColorDone,
  }) {
    return IrisImage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      isCirclingDone: isCirclingDone ?? this.isCirclingDone,
      isFlashDone: isFlashDone ?? this.isFlashDone,
      isColorDone: isColorDone ?? this.isColorDone,
    );
  }

  @override
  List<Object?> get props => [id, imagePath, isCirclingDone, isFlashDone, isColorDone];
}