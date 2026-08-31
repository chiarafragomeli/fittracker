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

  /// Ascolta messaggi in ingresso dall'Apple Watch
  /// (es. allenamento completato dal polso)
  void initializeListener({
    required Function(Map<String, dynamic> workoutData) onWorkoutCompleted,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWorkoutCompleted') {
        final data = Map<String, dynamic>.from(call.arguments as Map);
        onWorkoutCompleted(data);
      }
    });
  }
}
