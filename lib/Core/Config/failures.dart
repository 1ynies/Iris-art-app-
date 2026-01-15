import 'package:equatable/equatable.dart';

/// Abstract class to define the base Failure
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// --- Specific Failure Types ---

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

// You can add feature-specific failures if needed
class EditorSaveFailure extends Failure {
  const EditorSaveFailure(String message) : super(message);
}