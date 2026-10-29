import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models.dart';
import '../../core/database/repositories_provider.dart';
import '../../core/services/health_service.dart';
import '../../core/watch_connector.dart';
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
  DateTime? _restEndTime;
  AppLifecycleListener? _lifecycleListener;

  @override
  WorkoutState build() {
    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppPaused,
      onHide: _onAppPaused,
      onResume: _onAppResumed,
      onShow: _onAppResumed,
    );
    ref.onDispose(() {
      _timer?.cancel();
      _lifecycleListener?.dispose();
    });
    ref.read(watchConnectorProvider).initializeListener(
      onWorkoutCompleted: _handleWatchWorkoutCompleted,
      onWorkoutStarted: _handleWatchWorkoutStarted,
      onWorkoutDiscarded: _handleWatchWorkoutDiscarded,
      onSetCompleted: _handleWatchSetCompleted,
    );
    return WorkoutState();
  }

  void _handleWatchSetCompleted(Map<String, dynamic> data) {
    if (!state.isTracking || state.activeSets == null) return;

    final exerciseId = data['exerciseId']?.toString();
    final setIndex = (data['setIndex'] as num?)?.toInt() ?? 0;
    final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
    final reps = (data['reps'] as num?)?.toInt() ?? 0;
    final durationSeconds = (data['durationSeconds'] as num?)?.toInt() ?? 0;
    final restSeconds = (data['restSeconds'] as num?)?.toInt() ?? 0;

    if (exerciseId == null || !state.activeSets!.containsKey(exerciseId)) return;

    final updatedSets = Map<String, List<Map<String, dynamic>>>.from(
      state.activeSets!.map(
        (k, v) => MapEntry(
          k,
          List<Map<String, dynamic>>.from(
            v.map((e) => Map<String, dynamic>.from(e)),
          ),
        ),
      ),
    );

    final exerciseSets = updatedSets[exerciseId]!;
    while (exerciseSets.length <= setIndex) {
      exerciseSets.add({
        'weight': weight,
        'reps': reps,
        'duration': durationSeconds,
        'done': false,
        'metricType': reps > 0 ? 'reps' : 'duration',
      });
    }

    final targetSet = exerciseSets[setIndex];
    targetSet['weight'] = weight;
    if (reps > 0) targetSet['reps'] = reps;
    if (durationSeconds > 0) targetSet['duration'] = durationSeconds;
    targetSet['done'] = true;

    if (restSeconds > 0) {
      startRestTimer(Duration(seconds: restSeconds));
    }

    state = state.copyWith(activeSets: updatedSets);
  }

  void _handleWatchWorkoutStarted(Map<String, dynamic> data) {
    final routineId = data['routineId']?.toString() ?? '';
    final workoutId = (data['workoutId'] ?? data['id'])?.toString();
    final startTimeMs = (data['startTimeMs'] as num?)?.toInt();
    final startTime = startTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startTimeMs)
        : null;

    if (state.isTracking) {
      if (state.currentWorkout?.id == workoutId) return;
    }

    final routinesRepo = ref.read(routinesRepositoryProvider);
    final routine = routinesRepo.getRoutine(routineId);
    if (routine != null) {
      startWorkout(routine, customId: workoutId, customStartTime: startTime);
    }
  }

  void _handleWatchWorkoutDiscarded(Map<String, dynamic> data) {
    final workoutId = (data['workoutId'] ?? data['id'])?.toString();
    if (state.isTracking &&
        (workoutId == null || state.currentWorkout?.id == workoutId)) {
      discardWorkout();
    }
  }

  void _onAppPaused() {
    // Pause UI polling timer when screen is off or app is backgrounded to save battery
    _timer?.cancel();
    _timer = null;
  }

  void _onAppResumed() {
    if (state.isTracking) {
      _tick();
      _startTimer();
    }
  }

  void _handleWatchWorkoutCompleted(Map<String, dynamic> data) {
    final endTimeMs = (data['endTimeMs'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    final durationSecs = (data['duration'] as num?)?.toDouble() ?? 0.0;
    final startTimeMs = (data['startTimeMs'] as num?)?.toInt() ??
        (endTimeMs - (durationSecs * 1000).round());

    final id = (data['id'] as String?)?.isNotEmpty == true
        ? data['id'] as String
        : 'watch_$startTimeMs';
    final name = (data['name'] as String?)?.isNotEmpty == true
        ? data['name'] as String
        : 'Allenamento Watch';

    final rawSets = data['sets'];
    final List<WorkoutSet> completedSets = [];
    if (rawSets is List) {
      for (int i = 0; i < rawSets.length; i++) {
        final item = rawSets[i];
        if (item is Map) {
          final exId = item['exerciseId']?.toString() ?? '';
          if (exId.isEmpty) continue;
          completedSets.add(
            WorkoutSet(
              id: '${id}_set_$i',
              exerciseId: exId,
              weight: (item['weight'] as num?)?.toDouble() ?? 0.0,
              reps: (item['reps'] as num?)?.toInt() ?? 0,
              durationSeconds: (item['durationSeconds'] as num?)?.toInt() ?? 0,
              isCompleted: (item['isCompleted'] as bool?) ?? true,
            ),
          );
        }
      }
    }

    final watchLog = WorkoutLog(
      id: id,
      name: name,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTimeMs),
      endTime: DateTime.fromMillisecondsSinceEpoch(endTimeMs),
      sets: completedSets,
    );

    final logsRepo = ref.read(workoutLogsRepositoryProvider);
    logsRepo.saveLog(watchLog);

    if (state.isTracking &&
        (state.currentWorkout?.id == id ||
            state.currentWorkout?.name == name)) {
      _timer?.cancel();
      _restEndTime = null;
      state = WorkoutState();
    }
  }

  void startWorkout(
    Routine routine, {
    String? customId,
    DateTime? customStartTime,
  }) {
    final exercisesRepo = ref.read(exercisesRepositoryProvider);
    final startTime = customStartTime ?? DateTime.now();

    final newWorkout = WorkoutLog(
      id: customId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: routine.name,
      startTime: startTime,
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

    _restEndTime = null;
    state = WorkoutState(
      currentWorkout: newWorkout,
      activeRoutine: routine,
      activeSets: initialSets,
      isTracking: true,
      isMinimized: false,
      elapsedTime: Duration.zero,
    );

    if (customId == null) {
      ref.read(watchConnectorProvider).startWorkoutOnWatch(
        routineId: routine.id,
        routineName: routine.name,
        workoutId: newWorkout.id,
        startTimeMs: startTime.millisecondsSinceEpoch,
      );
    }

    ref.read(watchConnectorProvider).startLiveActivity(
      workoutId: newWorkout.id,
      routineName: routine.name,
      startTimeMs: startTime.millisecondsSinceEpoch,
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

  void _tick() {
    if (!state.isTracking || state.currentWorkout == null) return;

    final now = DateTime.now();
    final newElapsed = now.difference(state.currentWorkout!.startTime);

    Duration? newRestTimer;
    bool justFinished = false;
    if (_restEndTime != null) {
      final remainingMs = _restEndTime!.difference(now).inMilliseconds;
      if (remainingMs > 0) {
        newRestTimer = Duration(seconds: (remainingMs / 1000).ceil());
      } else {
        justFinished = true;
        _restEndTime = null;
        newRestTimer = null;
        _SoundService.playRestDone();
      }
    }

    if (newElapsed.inSeconds != state.elapsedTime.inSeconds ||
        newRestTimer?.inSeconds != state.restTimer?.inSeconds ||
        justFinished) {
      state = state.copyWith(
        elapsedTime: newElapsed,
        restTimer: newRestTimer,
        restTimerJustFinished: justFinished,
        clearRestTimer: newRestTimer == null,
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void startRestTimer(Duration duration) {
    _restEndTime = DateTime.now().add(duration);
    state = state.copyWith(
      restTimer: duration,
      restTimerJustFinished: false,
    );
  }

  void cancelRestTimer() {
    _restEndTime = null;
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
    
    final wId = state.currentWorkout?.id;
    if (wId != null) {
      ref.read(watchConnectorProvider).endWorkoutOnWatch(workoutId: wId);
    }
    ref.read(watchConnectorProvider).endLiveActivity();

    _timer?.cancel();
    _restEndTime = null;
    state = WorkoutState();
  }

  void discardWorkout() {
    final wId = state.currentWorkout?.id;
    if (wId != null) {
      ref.read(watchConnectorProvider).endWorkoutOnWatch(workoutId: wId);
    }
    ref.read(watchConnectorProvider).endLiveActivity();

    _timer?.cancel();
    _restEndTime = null;
    state = WorkoutState();
  }
}

final workoutProvider = NotifierProvider<WorkoutNotifier, WorkoutState>(() {
  return WorkoutNotifier();
});
