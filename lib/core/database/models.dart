import 'package:hive/hive.dart';

enum MetricType { reps, duration }

// --- Models ---

class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final bool isCustom;
  final String notes; // Note di esecuzione
  final MetricType metricType;
  final bool isDeleted;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.isCustom = false,
    this.notes = '',
    this.metricType = MetricType.reps,
    this.isDeleted = false,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    bool? isCustom,
    String? notes,
    MetricType? metricType,
    bool? isDeleted,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      isCustom: isCustom ?? this.isCustom,
      notes: notes ?? this.notes,
      metricType: metricType ?? this.metricType,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class WorkoutSet {
  final String id;
  final String exerciseId;
  final double weight;
  final int reps;
  final int durationSeconds;
  final bool isCompleted;

  WorkoutSet({
    required this.id,
    required this.exerciseId,
    this.weight = 0.0,
    this.reps = 0,
    this.durationSeconds = 0,
    this.isCompleted = false,
  });

  WorkoutSet copyWith({
    String? id,
    String? exerciseId,
    double? weight,
    int? reps,
    int? durationSeconds,
    bool? isCompleted,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Configurazione predefinita per un esercizio in una Routine
/// (serie, reps, pausa e note di esecuzione specifiche per questa scheda)
class ExerciseConfig {
  final String exerciseId;
  final int defaultSets;
  final int defaultReps;
  final int defaultDuration;
  final int restSeconds;
  final String routineNotes; // Note specifiche per questa scheda

  ExerciseConfig({
    required this.exerciseId,
    this.defaultSets = 3,
    this.defaultReps = 8,
    this.defaultDuration = 30,
    this.restSeconds = 90,
    this.routineNotes = '',
  });

  ExerciseConfig copyWith({
    String? exerciseId,
    int? defaultSets,
    int? defaultReps,
    int? defaultDuration,
    int? restSeconds,
    String? routineNotes,
  }) {
    return ExerciseConfig(
      exerciseId: exerciseId ?? this.exerciseId,
      defaultSets: defaultSets ?? this.defaultSets,
      defaultReps: defaultReps ?? this.defaultReps,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      restSeconds: restSeconds ?? this.restSeconds,
      routineNotes: routineNotes ?? this.routineNotes,
    );
  }
}

class Routine {
  final String id;
  final String name;
  final List<String> exerciseIds;
  final String? healthActivityType;

  /// Configurazioni per esercizio: mappa exerciseId -> ExerciseConfig
  final Map<String, ExerciseConfig> exerciseConfigs;

  Routine({
    required this.id,
    required this.name,
    required this.exerciseIds,
    this.healthActivityType,
    Map<String, ExerciseConfig>? exerciseConfigs,
  }) : exerciseConfigs = exerciseConfigs ?? {};

  Routine copyWith({
    String? id,
    String? name,
    List<String>? exerciseIds,
    String? healthActivityType,
    Map<String, ExerciseConfig>? exerciseConfigs,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      healthActivityType: healthActivityType ?? this.healthActivityType,
      exerciseConfigs: exerciseConfigs ?? this.exerciseConfigs,
    );
  }
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

  WorkoutLog copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sets: sets ?? List.from(this.sets),
    );
  }
}

// --- Hive TypeAdapters ---

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final int typeId = 0;

  @override
  Exercise read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final muscleGroup = reader.readString();
    final isCustom = reader.readBool();
    String notes = '';
    try {
      notes = reader.readString();
    } catch (_) {}
    int metricIdx = 0;
    try {
      metricIdx = reader.readInt();
    } catch (_) {}
    bool isDeleted = false;
    try {
      isDeleted = reader.readBool();
    } catch (_) {}
    return Exercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      isCustom: isCustom,
      notes: notes,
      metricType: MetricType.values[metricIdx.clamp(0, 1)],
      isDeleted: isDeleted,
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.muscleGroup);
    writer.writeBool(obj.isCustom);
    writer.writeString(obj.notes);
    writer.writeInt(obj.metricType.index);
    writer.writeBool(obj.isDeleted);
  }
}

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final int typeId = 1;

  @override
  WorkoutSet read(BinaryReader reader) {
    final id = reader.readString();
    final exerciseId = reader.readString();
    final weight = reader.readDouble();
    final reps = reader.readInt();
    final isCompleted = reader.readBool();
    int dur = 0;
    try {
      dur = reader.readInt();
    } catch (_) {}
    return WorkoutSet(
      id: id,
      exerciseId: exerciseId,
      weight: weight,
      reps: reps,
      isCompleted: isCompleted,
      durationSeconds: dur,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.exerciseId);
    writer.writeDouble(obj.weight);
    writer.writeInt(obj.reps);
    writer.writeBool(obj.isCompleted);
    writer.writeInt(obj.durationSeconds);
  }
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 2;

  @override
  Routine read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final exerciseIds = reader.readStringList();

    // Read exercise configs (new field – safe fallback if old data)
    Map<String, ExerciseConfig> configs = {};
    try {
      final count = reader.readInt();
      for (int i = 0; i < count; i++) {
        final exId = reader.readString();
        final sets = reader.readInt();
        final reps = reader.readInt();
        final rest = reader.readInt();
        String rNotes = '';
        try {
          rNotes = reader.readString();
        } catch (_) {}
        int dur = 30;
        try {
          dur = reader.readInt();
        } catch (_) {}
        configs[exId] = ExerciseConfig(
          exerciseId: exId,
          defaultSets: sets,
          defaultReps: reps,
          defaultDuration: dur,
          restSeconds: rest,
          routineNotes: rNotes,
        );
      }
    } catch (_) {
      // Old data without configs — use defaults
    }
    String? healthType;
    try {
      healthType = reader.readString();
      if (healthType.isEmpty) healthType = null;
    } catch (_) {}

    return Routine(
      id: id,
      name: name,
      exerciseIds: exerciseIds,
      exerciseConfigs: configs,
      healthActivityType: healthType,
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeStringList(obj.exerciseIds);
    
    writer.writeInt(obj.exerciseConfigs.length);
    obj.exerciseConfigs.forEach((exId, cfg) {
      writer.writeString(exId);
      writer.writeInt(cfg.defaultSets);
      writer.writeInt(cfg.defaultReps);
      writer.writeInt(cfg.restSeconds);
      writer.writeString(cfg.routineNotes);
      writer.writeInt(cfg.defaultDuration);
    });
    
    writer.writeString(obj.healthActivityType ?? '');
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
