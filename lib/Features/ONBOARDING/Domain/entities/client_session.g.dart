// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientSessionAdapter extends TypeAdapter<ClientSession> {
  @override
  final int typeId = 0;

  @override
  ClientSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClientSession(
      id: fields[0] as String,
      clientName: fields[1] as String,
      email: fields[2] as String,
      country: fields[3] as String,
      importedPhotos: (fields[4] as List).cast<String>(),
      generatedArt: (fields[5] as List).cast<String>(),
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ClientSession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.importedPhotos)
      ..writeByte(5)
      ..write(obj.generatedArt)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
