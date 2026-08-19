import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'exercises_repository.dart';
import 'routines_repository.dart';
import 'workout_logs_repository.dart';

final exercisesRepositoryProvider = Provider<ExercisesRepository>((ref) {
  return ExercisesRepository(Hive.box<Exercise>('exercises'));
});

final routinesRepositoryProvider = Provider<RoutinesRepository>((ref) {
  return RoutinesRepository(Hive.box<Routine>('routines'));
});

final workoutLogsRepositoryProvider = Provider<WorkoutLogsRepository>((ref) {
  return WorkoutLogsRepository(Hive.box<WorkoutLog>('workout_logs'));
});
