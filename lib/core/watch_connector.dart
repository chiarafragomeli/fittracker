import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider per esporre il connettore in tutta l'app
final watchConnectorProvider = Provider((ref) => WatchConnector());

class WatchConnector {
  static const MethodChannel _channel = MethodChannel('gym_tracker/watch');

  /// Invia il comando all'Apple Watch per avviare il tracciamento
  Future<void> sendWorkoutStarted(String workoutId, String name) async {
    try {
      await _channel.invokeMethod('workoutStarted', {
        'id': workoutId,
        'name': name,
      });
    } on PlatformException catch (e) {
      print("Impossibile comunicare con Apple Watch: '${e.message}'.");
    }
  }

  /// Sincronizza l'aggiunta di un nuovo set (es. 10 reps x 50kg)
  Future<void> sendSetLogged(
    String exerciseName,
    int reps,
    double weight,
  ) async {
    try {
      await _channel.invokeMethod('setLogged', {
        'exercise': exerciseName,
        'reps': reps,
        'weight': weight,
      });
    } on PlatformException catch (e) {
      print("Impossibile comunicare con Apple Watch: '${e.message}'.");
    }
  }

  /// Ferma l'allenamento anche sull'orologio
  Future<void> sendWorkoutFinished() async {
    try {
      await _channel.invokeMethod('workoutFinished');
    } on PlatformException catch (e) {
      print("Impossibile comunicare con Apple Watch: '${e.message}'.");
    }
  }

  /// Ascolta messaggi in ingresso dall'Apple Watch (es. utente preme "Fine Set" dal polso)
  void initializeListener(
    Function(String, Map<String, dynamic>) onMessageReceived,
  ) {
    _channel.setMethodCallHandler((call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      onMessageReceived(call.method, args);
    });
  }
}
