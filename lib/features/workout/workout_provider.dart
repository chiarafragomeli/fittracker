import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/models.dart';

// State of the current workout
class WorkoutState {
  final WorkoutLog? currentWorkout;
  final bool isTracking;
  final Duration elapsedTime;
  final Duration? restTimer;

  WorkoutState({
    this.currentWorkout,
    this.isTracking = false,
    this.elapsedTime = Duration.zero,
    this.restTimer,
  });

  WorkoutState copyWith({
    WorkoutLog? currentWorkout,
    bool? isTracking,
    Duration? elapsedTime,
    Duration? restTimer,
  }) {
    return WorkoutState(
      currentWorkout: currentWorkout ?? this.currentWorkout,
      isTracking: isTracking ?? this.isTracking,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      restTimer: restTimer, // Can be null
    );
  }
}

final workoutProvider = StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier();
});

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  Timer? _timer;
  Timer? _restTimer;

  WorkoutNotifier() : super(WorkoutState());

  void startWorkout(Routine routine) {
    final newWorkout = WorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: routine.name,
      startTime: DateTime.now(),
      sets: [], // will be populated
    );

    state = state.copyWith(
      currentWorkout: newWorkout,
      isTracking: true,
      elapsedTime: Duration.zero,
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isTracking) {
        state = state.copyWith(
          elapsedTime: state.elapsedTime + const Duration(seconds: 1),
          restTimer: state.restTimer != null && state.restTimer!.inSeconds > 0
              ? state.restTimer! - const Duration(seconds: 1)
              : null,
        );
      }
    });
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
      currentWorkout: WorkoutLog(
        id: state.currentWorkout!.id,
        name: state.currentWorkout!.name,
        startTime: state.currentWorkout!.startTime,
        sets: updatedSets,
      ),
    );

    // Start rest timer (e.g. 90 seconds)
    startRestTimer(const Duration(seconds: 90));
  }

  void startRestTimer(Duration duration) {
    state = state.copyWith(restTimer: duration);
  }

  void finishWorkout() {
    if (state.currentWorkout == null) return;

    final finishedWorkout = WorkoutLog(
      id: state.currentWorkout!.id,
      name: state.currentWorkout!.name,
      startTime: state.currentWorkout!.startTime,
      endTime: DateTime.now(),
      sets: state.currentWorkout!.sets,
    );

    // Save to Hive
    final box = Hive.box<WorkoutLog>('workout_logs');
    box.put(finishedWorkout.id, finishedWorkout);

    _timer?.cancel();
    _restTimer?.cancel();
    
    state = WorkoutState(); // Reset
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }
}
