// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      note: fields[1] as String,
      dueDate: fields[2] as DateTime,
      isCompleted: fields[4] as bool,
      repetitionFrequency: fields[6] as String,
      reminderMinutes: fields[7] as int,
      timeHour: fields[8] as int,
      timeMinute: fields[9] as int,
      alarmTone: fields[10] as String,
      key: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.note)
      ..writeByte(2)
      ..write(obj.dueDate)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.repetitionFrequency)
      ..writeByte(7)
      ..write(obj.reminderMinutes)
      ..writeByte(8)
      ..write(obj.timeHour)
      ..writeByte(9)
      ..write(obj.timeMinute)
      ..writeByte(10)
      ..write(obj.alarmTone)
      ..writeByte(11)
      ..write(obj.key);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
