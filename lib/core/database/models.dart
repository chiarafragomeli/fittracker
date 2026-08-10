import 'package:hive/hive.dart';

// --- Models ---

class Exercise {
  final String id;
  final String name;
  final String muscleGroup; // es. Chest, Back, Legs
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.isCustom = false,
  });
}

class WorkoutSet {
  final String id;
  final String exerciseId;
  final double weight;
  final int reps;
  final bool isCompleted;

  WorkoutSet({
    required this.id,
    required this.exerciseId,
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Routine {
  final String id;
  final String name;
  final List<String> exerciseIds; // Ordinamento esercizi nella routine

  Routine({
    required this.id,
    required this.name,
    required this.exerciseIds,
  });
}

class WorkoutLog {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutSet> sets;

  WorkoutLog({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.sets,
  });
}

// --- Hive TypeAdapters ---

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 0;

  @override
  Exercise read(BinaryReader reader) {
    return Exercise(
      id: reader.readString(),
      name: reader.readString(),
      muscleGroup: reader.readString(),
      isCustom: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.muscleGroup);
    writer.writeBool(obj.isCustom);
  }
}

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final int typeId = 1;

  @override
  WorkoutSet read(BinaryReader reader) {
    return WorkoutSet(
      id: reader.readString(),
      exerciseId: reader.readString(),
      weight: reader.readDouble(),
      reps: reader.readInt(),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.exerciseId);
    writer.writeDouble(obj.weight);
    writer.writeInt(obj.reps);
    writer.writeBool(obj.isCompleted);
  }
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 2;

  @override
  Routine read(BinaryReader reader) {
    return Routine(
      id: reader.readString(),
      name: reader.readString(),
      exerciseIds: reader.readStringList(),
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeStringList(obj.exerciseIds);
  }
}

class WorkoutLogAdapter extends TypeAdapter<WorkoutLog> {
  @override
  final int typeId = 3;

  @override
  WorkoutLog read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final startTime = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final hasEndTime = reader.readBool();
    DateTime? endTime;
    if (hasEndTime) {
      endTime = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    }
    final setsList = reader.readList().cast<WorkoutSet>();

    return WorkoutLog(
      id: id,
      name: name,
      startTime: startTime,
      endTime: endTime,
      sets: setsList,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutLog obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.startTime.millisecondsSinceEpoch);
    writer.writeBool(obj.endTime != null);
    if (obj.endTime != null) {
      writer.writeInt(obj.endTime!.millisecondsSinceEpoch);
    }
    writer.writeList(obj.sets);
  }
}
