// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 0;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentModel(
      id: fields[0] as String,
      documentName: fields[1] as String,
      filePath: fields[2] as String,
      expiryDate: fields[3] as DateTime,
      reminderEnabled: fields[4] as bool,
      reminderOffsetDays: fields[5] as int,
      notificationId: fields[6] as int?,
      createdAt: fields[7] as DateTime?,
      reminderHour: fields[8] as int? ?? 9,
      reminderMinute: fields[9] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.documentName)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.expiryDate)
      ..writeByte(4)
      ..write(obj.reminderEnabled)
      ..writeByte(5)
      ..write(obj.reminderOffsetDays)
      ..writeByte(6)
      ..write(obj.notificationId)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.reminderHour)
      ..writeByte(9)
      ..write(obj.reminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
