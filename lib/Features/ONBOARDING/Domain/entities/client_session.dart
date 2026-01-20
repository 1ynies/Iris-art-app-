import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'client_session.g.dart';

@HiveType(typeId: 0)
class ClientSession extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String clientName;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String country;

  @HiveField(4) // ✅ New: Store imported image paths
  final List<String> importedPhotos;

  @HiveField(5) // ✅ New: Store generated art paths
  final List<String> generatedArt;

  @HiveField(6) // ✅ New: Track creation time for 24h expiry
  final DateTime createdAt;

  const ClientSession({
    required this.id,
    required this.clientName,
    required this.email,
    required this.country,
    this.importedPhotos = const [],
    this.generatedArt = const [],
    required this.createdAt,
  });

  // CopyWith helper to update lists easily
  ClientSession copyWith({
    String? id,
    String? clientName,
    String? email,
    String? country,
    List<String>? importedPhotos,
    List<String>? generatedArt,
    DateTime? createdAt,
  }) {
    return ClientSession(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      email: email ?? this.email,
      country: country ?? this.country,
      importedPhotos: importedPhotos ?? this.importedPhotos,
      generatedArt: generatedArt ?? this.generatedArt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, clientName, email, country, importedPhotos, generatedArt, createdAt];
}