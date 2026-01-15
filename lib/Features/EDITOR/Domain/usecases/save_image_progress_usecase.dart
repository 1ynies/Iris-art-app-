import 'package:dartz/dartz.dart';
import 'package:iris_designer/Core/Config/failures.dart';
import 'package:iris_designer/Features/EDITOR/Domain/entities/iris_image.dart';

class SaveImageProgressUseCase {
  // In a real app, this would talk to a Repository.
  // For now, we simulate success.
  Future<Either<Failure, bool>> call(List<IrisImage> images) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return const Right(true);
  }
}