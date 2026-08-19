import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class RoutinesRepository {
  final Box<Routine> _box;

  RoutinesRepository(this._box);

  List<Routine> getAllRoutines() {
    return _box.values.toList();
  }

  Routine? getRoutine(String id) {
    return _box.get(id);
  }

  static void preloadDefaults(Box<Routine> box) {
    final defaults = [
      Routine(
        id: 'r_1a',
        name: 'Giorno 1A',
        exerciseIds: ['ex_1', 'ex_2', 'ex_3', 'ex_4', 'ex_7', 'ex_16', 'ex_8', 'ex_23', 'ex_21', 'ex_15'],
      ),
      Routine(
        id: 'r_1b',
        name: 'Giorno 1B',
        exerciseIds: ['ex_2', 'ex_4', 'ex_18', 'ex_22', 'ex_17', 'ex_25', 'ex_27', 'ex_5'],
      ),
      Routine(
        id: 'r_1c',
        name: 'Giorno 1C (Scheda 1 C)',
        exerciseIds: ['ex_1', 'ex_3', 'ex_4', 'ex_9', 'ex_7', 'ex_10', 'ex_11', 'ex_12'],
      ),
      Routine(
        id: 'r_2a',
        name: 'Giorno 2A',
        exerciseIds: ['ex_1', 'ex_2', 'ex_3', 'ex_4', 'ex_9', 'ex_24', 'ex_13', 'ex_29', 'ex_14'],
      ),
      Routine(
        id: 'r_2b',
        name: 'Giorno 2B',
        exerciseIds: ['ex_2', 'ex_4', 'ex_19', 'ex_20', 'ex_23', 'ex_26', 'ex_28', 'ex_5'],
      ),
      Routine(
        id: 'r_2c',
        name: 'Giorno 2C',
        exerciseIds: ['ex_1', 'ex_3', 'ex_4', 'ex_7', 'ex_30', 'ex_31', 'ex_21', 'ex_11'],
        exerciseConfigs: {
          'ex_11': ExerciseConfig(
            exerciseId: 'ex_11',
            routineNotes: '10 ripetizioni con un peso che faccia arrivare a sfinimento, recupero 10 secondi, ripartire arrivando a sfinimento (dovrebbero venire dalle 4 alle 6 ripetizioni non di più, se il carico è giusto). Questa è una sola serie.',
          ),
        },
      ),
    ];
    for (var r in defaults) {
      box.put(r.id, r);
    }
  }

  void saveRoutine(Routine routine) {
    _box.put(routine.id, routine);
  }

  void deleteRoutine(String id) {
    _box.delete(id);
  }

  bool get isEmpty => _box.isEmpty;

  bool containsKey(String key) => _box.containsKey(key);
}
