import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models.dart';
import '../../core/database/repositories_provider.dart';
import '../../core/services/health_service.dart';
import '../settings/settings_provider.dart';

// Sound service via iOS native channel
class _SoundService {
  static const _channel = MethodChannel('gym_tracker/sound');

  static Future<void> playRestDone() async {
    try {
      await _channel.invokeMethod('playRestDone');
    } catch (_) {}
  }
}

// State of the current workout
class WorkoutState {
  final WorkoutLog? currentWorkout;
  final Routine? activeRoutine;
  final Map<String, List<Map<String, dynamic>>>? activeSets;
  final bool isTracking;
  final bool isMinimized;
  final Duration elapsedTime;
  final Duration? restTimer;
  final bool restTimerJustFinished;

  WorkoutState({
    this.currentWorkout,
    this.activeRoutine,
    this.activeSets,
    this.isTracking = false,
    this.isMinimized = false,
    this.elapsedTime = Duration.zero,
    this.restTimer,
    this.restTimerJustFinished = false,
  });

  WorkoutState copyWith({
    WorkoutLog? currentWorkout,
    Routine? activeRoutine,
    Map<String, List<Map<String, dynamic>>>? activeSets,
    bool? isTracking,
    bool? isMinimized,
    Duration? elapsedTime,
    Duration? restTimer,
    bool? restTimerJustFinished,
    bool clearRestTimer = false,
  }) {
    return WorkoutState(
      currentWorkout: currentWorkout ?? this.currentWorkout,
      activeRoutine: activeRoutine ?? this.activeRoutine,
      activeSets: activeSets ?? this.activeSets,
      isTracking: isTracking ?? this.isTracking,
      isMinimized: isMinimized ?? this.isMinimized,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      restTimer: clearRestTimer ? null : (restTimer ?? this.restTimer),
      restTimerJustFinished:
          restTimerJustFinished ?? this.restTimerJustFinished,
    );
  }
}

class WorkoutNotifier extends Notifier<WorkoutState> {
  Timer? _timer;

  @override
  WorkoutState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return WorkoutState();
  }

  void startWorkout(Routine routine) {
    final exercisesRepo = ref.read(exercisesRepositoryProvider);
    
    final newWorkout = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: routine.name,
      startTime: DateTime.now(),
      sets: [],
    );

    // Inizializza i set correnti
    final initialSets = <String, List<Map<String, dynamic>>>{};
    for (final exId in routine.exerciseIds) {
      final cfg =
          routine.exerciseConfigs[exId] ?? ExerciseConfig(exerciseId: exId);
      final exercise = exercisesRepo.getExercise(exId);
      final isDuration = exercise?.metricType == MetricType.duration;
      initialSets[exId] = List.generate(
        cfg.defaultSets,
        (_) => {
          'weight': 0.0,
          'done': false,
          if (isDuration)
            'duration': cfg.defaultDuration
          else
            'reps': cfg.defaultReps,
          'metricType': isDuration ? 'duration' : 'reps',
        },
      );
    }

    state = WorkoutState(
      currentWorkout: newWorkout,
      activeRoutine: routine,
      activeSets: initialSets,
      isTracking: true,
      isMinimized: false,
      elapsedTime: Duration.zero,
    );

    _startTimer();
  }

  void updateActiveSets(Map<String, List<Map<String, dynamic>>> newSets) {
    state = state.copyWith(activeSets: newSets);
  }

  void updateWorkoutName(String newName) {
    if (state.currentWorkout == null) return;
    state = state.copyWith(
      currentWorkout: state.currentWorkout!.copyWith(name: newName),
    );
  }

  void minimizeWorkout() {
    state = state.copyWith(isMinimized: true);
  }

  void maximizeWorkout() {
    state = state.copyWith(isMinimized: false);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isTracking) return;

      Duration? newRestTimer = state.restTimer;
      bool justFinished = false;
      if (newRestTimer != null) {
        if (newRestTimer.inSeconds > 0) {
          newRestTimer = newRestTimer - const Duration(seconds: 1);
        } else {
          justFinished = true;
          newRestTimer = null;
          _SoundService.playRestDone();
        }
      }

      state = state.copyWith(
        elapsedTime: state.elapsedTime + const Duration(seconds: 1),
        restTimer: newRestTimer,
        restTimerJustFinished: justFinished,
        clearRestTimer: newRestTimer == null,
      );
    });
  }

  void startRestTimer(Duration duration) {
    state = state.copyWith(
      restTimer: duration,
      restTimerJustFinished: false,
    );
  }

  void cancelRestTimer() {
    state = state.copyWith(
      restTimerJustFinished: false,
      clearRestTimer: true,
    );
  }

  void acknowledgeRestFinished() {
    state = state.copyWith(restTimerJustFinished: false);
  }

  void logSet(WorkoutSet set) {
    if (state.currentWorkout == null) return;
    final updatedSets = List<WorkoutSet>.from(state.currentWorkout!.sets);
    final index = updatedSets.indexWhere((s) => s.id == set.id);
    if (index >= 0) {
      updatedSets[index] = set;
    } else {
      updatedSets.add(set);
    }
    state = state.copyWith(
      currentWorkout: state.currentWorkout!.copyWith(sets: updatedSets),
    );
  }

  void finishWorkout() {
    if (state.currentWorkout == null || state.activeSets == null) return;

    final List<WorkoutSet> completedSets = [];
    state.activeSets!.forEach((exId, setsList) {
      for (final setMap in setsList) {
        final isDuration = setMap['metricType'] == 'duration';
        completedSets.add(
          WorkoutSet(
            id: DateTime.now().microsecondsSinceEpoch.toString() + '_' + exId,
            exerciseId: exId,
            weight: (setMap['weight'] as num).toDouble(),
            reps: isDuration ? 0 : (setMap['reps'] as num).toInt(),
            durationSeconds: isDuration
                ? ((setMap['duration'] ?? 0) as num).toInt()
                : 0,
            isCompleted: setMap['done'] as bool,
          ),
        );
      }
    });

    final finishedWorkout = state.currentWorkout!.copyWith(
      endTime: DateTime.now(),
      sets: completedSets,
    );
    
    final logsRepo = ref.read(workoutLogsRepositoryProvider);
    logsRepo.saveLog(finishedWorkout);
    
    // Sync with Apple Health
    final syncEnabled = ref.read(settingsProvider);
    if (syncEnabled && state.activeRoutine != null) {
      final activityType = state.activeRoutine!.healthActivityType;
      
      if (activityType != null && activityType != 'none') {
        final healthService = HealthService();
        healthService.saveWorkout(
          start: finishedWorkout.startTime,
          end: finishedWorkout.endTime!,
          activityTypeStr: activityType,
        );
      }
    }
    
    _timer?.cancel();
    state = WorkoutState();
  }

  void discardWorkout() {
    _timer?.cancel();
    state = WorkoutState();
  }
}

final workoutProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(() {
  return WorkoutNotifier();
});
