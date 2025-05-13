// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class APISettingsAdapter extends TypeAdapter<APISettings> {
  @override
  final int typeId = 0;

  @override
  APISettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return APISettings(
      openAIKey: fields[0] as String?,
      model: fields[1] as String?,
      useOCR: fields[2] as bool,
      enableBrowsing: fields[3] as bool,
      enableWhisper: fields[4] as bool,
      enableSpeechRecognition: fields[5] as bool,
      speechLocale: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, APISettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.openAIKey)
      ..writeByte(1)
      ..write(obj.model)
      ..writeByte(2)
      ..write(obj.useOCR)
      ..writeByte(3)
      ..write(obj.enableBrowsing)
      ..writeByte(4)
      ..write(obj.enableWhisper)
      ..writeByte(5)
      ..write(obj.enableSpeechRecognition)
      ..writeByte(6)
      ..write(obj.speechLocale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is APISettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
