import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/models.dart';

/// Provider per esporre il connettore Watch in tutta l'app
final watchConnectorProvider = Provider((ref) => WatchConnector());

class WatchConnector {
  static const MethodChannel _channel = MethodChannel('gym_tracker/watch');

  /// Sincronizza tutte le schede e gli esercizi al Watch.
  /// Chiamare dopo ogni modifica a schede o esercizi.
  Future<bool> syncRoutinesToWatch({
    required List<Routine> routines,
    required List<Exercise> exercises,
  }) async {
    try {
      // Costruisci la lista di esercizi come mappa per lookup rapido
      final exerciseMap = {for (final ex in exercises) ex.id: ex};

      // Serializza le routine con gli esercizi espansi
      final routinesJson = routines.map((routine) {
        final expandedExercises = routine.exerciseIds.map((exId) {
          final ex = exerciseMap[exId];
          final cfg = routine.exerciseConfigs[exId] ??
              ExerciseConfig(exerciseId: exId);
          return {
            'id': exId,
            'name': ex?.name ?? 'Esercizio sconosciuto',
            'muscleGroup': ex?.muscleGroup ?? '',
            'metricType': ex?.metricType == MetricType.duration ? 'duration' : 'reps',
            'defaultSets': cfg.defaultSets,
            'defaultReps': cfg.defaultReps,
            'defaultDuration': cfg.defaultDuration,
            'restSeconds': cfg.restSeconds,
          };
        }).toList();

        return {
          'id': routine.id,
          'name': routine.name,
          'exercises': expandedExercises,
          'healthActivityType': routine.healthActivityType,
        };
      }).toList();

      final jsonStr = jsonEncode(routinesJson);
      await _channel.invokeMethod('syncRoutinesToWatch', {
        'routines': jsonStr,
      });
      return true;
    } on PlatformException catch (e) {
      // Watch non connesso o non disponibile — non è un errore critico
      debugPrint("Watch sync failed: '${e.message}'");
      return false;
    } catch (e) {
      debugPrint("Watch sync error: $e");
      return false;
    }
  }

  /// Notifica l'Apple Watch dell'avvio di un allenamento
  Future<bool> startWorkoutOnWatch({
    required String routineId,
    required String routineName,
    required String workoutId,
    required int startTimeMs,
  }) async {
    try {
      await _channel.invokeMethod('startWorkoutOnWatch', {
        'routineId': routineId,
        'routineName': routineName,
        'workoutId': workoutId,
        'startTimeMs': startTimeMs,
      });
      return true;
    } catch (e) {
      debugPrint("startWorkoutOnWatch error: $e");
      return false;
    }
  }

  /// Notifica l'Apple Watch dell'annullamento/fine di un allenamento
  Future<bool> endWorkoutOnWatch({required String workoutId}) async {
    try {
      await _channel.invokeMethod('endWorkoutOnWatch', {
        'workoutId': workoutId,
      });
      return true;
    } catch (e) {
      debugPrint("endWorkoutOnWatch error: $e");
      return false;
    }
  }

  /// Sincronizza il completamento di una singola serie all'Apple Watch
  Future<bool> syncSetToWatch({
    required String workoutId,
    required String exerciseId,
    required int setIndex,
    required double weight,
    required int reps,
    required int durationSeconds,
    required int restSeconds,
  }) async {
    try {
      await _channel.invokeMethod('syncSetToWatch', {
        'workoutId': workoutId,
        'exerciseId': exerciseId,
        'setIndex': setIndex,
        'weight': weight,
        'reps': reps,
        'durationSeconds': durationSeconds,
        'restSeconds': restSeconds,
      });
      return true;
    } catch (e) {
      debugPrint("syncSetToWatch error: $e");
      return false;
    }
  }

  /// Avvia la Live Activity e Dynamic Island su iOS
  Future<bool> startLiveActivity({
    required String workoutId,
    required String routineName,
    required int startTimeMs,
    String exerciseName = '',
    String setInfo = '',
  }) async {
    try {
      await _channel.invokeMethod('startLiveActivity', {
        'workoutId': workoutId,
        'routineName': routineName,
        'startTimeMs': startTimeMs,
        'exerciseName': exerciseName,
        'setInfo': setInfo,
      });
      return true;
    } catch (e) {
      debugPrint("startLiveActivity error: $e");
      return false;
    }
  }

  /// Aggiorna la Live Activity e Dynamic Island
  Future<bool> updateLiveActivity({
    required String exerciseName,
    required String setInfo,
    bool isPaused = false,
  }) async {
    try {
      await _channel.invokeMethod('updateLiveActivity', {
        'exerciseName': exerciseName,
        'setInfo': setInfo,
        'isPaused': isPaused,
      });
      return true;
    } catch (e) {
      debugPrint("updateLiveActivity error: $e");
      return false;
    }
  }

  /// Chiude la Live Activity e Dynamic Island
  Future<bool> endLiveActivity() async {
    try {
      await _channel.invokeMethod('endLiveActivity');
      return true;
    } catch (e) {
      debugPrint("endLiveActivity error: $e");
      return false;
    }
  }

  /// Ascolta messaggi in ingresso dall'Apple Watch
  /// (avvio, completamento, annullamento, serie completata)
  void initializeListener({
    required Function(Map<String, dynamic> workoutData) onWorkoutCompleted,
    Function(Map<String, dynamic> workoutData)? onWorkoutStarted,
    Function(Map<String, dynamic> workoutData)? onWorkoutDiscarded,
    Function(Map<String, dynamic> setData)? onSetCompleted,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.arguments is! Map) return;
      final data = Map<String, dynamic>.from(call.arguments as Map);
      if (call.method == 'onWorkoutCompleted') {
        onWorkoutCompleted(data);
      } else if (call.method == 'onWorkoutStarted') {
        onWorkoutStarted?.call(data);
      } else if (call.method == 'onWorkoutDiscarded') {
        onWorkoutDiscarded?.call(data);
      } else if (call.method == 'onSetCompleted') {
        onSetCompleted?.call(data);
      }
    });
  }
}
