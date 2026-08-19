import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models.dart';
import '../../core/database/repositories_provider.dart';
import '../../core/database/routines_repository.dart';

class RoutinesNotifier extends Notifier<List<Routine>> {
  late RoutinesRepository _repository;

  @override
  List<Routine> build() {
    _repository = ref.watch(routinesRepositoryProvider);
    if (!_repository.containsKey('r_1a')) {
      _preloadDefaults();
    }
    return _repository.getAllRoutines();
  }

  void _preloadDefaults() {
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
      _repository.saveRoutine(r);
    }
  }

  void addRoutine(String name, List<String> exerciseIds) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoutine = Routine(id: newId, name: name, exerciseIds: exerciseIds);
    _repository.saveRoutine(newRoutine);
    state = _repository.getAllRoutines();
  }

  void updateRoutine(Routine updatedRoutine) {
    _repository.saveRoutine(updatedRoutine);
    state = _repository.getAllRoutines();
  }

  void deleteRoutine(String id) {
    _repository.deleteRoutine(id);
    state = _repository.getAllRoutines();
  }

  void reorderExercises(String routineId, int oldIndex, int newIndex) {
    final routine = _repository.getRoutine(routineId);
    if (routine == null) return;
    final exIds = List<String>.from(routine.exerciseIds);
    final item = exIds.removeAt(oldIndex);
    exIds.insert(newIndex, item);
    final updated = routine.copyWith(exerciseIds: exIds);
    _repository.saveRoutine(updated);
    state = _repository.getAllRoutines();
  }

  void removeExerciseFromRoutine(String routineId, String exerciseId) {
    final routine = _repository.getRoutine(routineId);
    if (routine == null) return;
    final exIds = List<String>.from(routine.exerciseIds);
    exIds.remove(exerciseId);
    final configs = Map<String, ExerciseConfig>.from(routine.exerciseConfigs);
    configs.remove(exerciseId);
    final updated = routine.copyWith(exerciseIds: exIds, exerciseConfigs: configs);
    _repository.saveRoutine(updated);
    state = _repository.getAllRoutines();
  }

  void addExerciseToRoutine(String routineId, String exerciseId) {
    final routine = _repository.getRoutine(routineId);
    if (routine == null) return;
    if (!routine.exerciseIds.contains(exerciseId)) {
      final exIds = List<String>.from(routine.exerciseIds)..add(exerciseId);
      final updated = routine.copyWith(exerciseIds: exIds);
      _repository.saveRoutine(updated);
      state = _repository.getAllRoutines();
    }
  }
}

final routinesProvider = NotifierProvider<RoutinesNotifier, List<Routine>>(() => RoutinesNotifier());
