import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models.dart';
import '../../core/database/repositories_provider.dart';
import '../../core/database/routines_repository.dart';
import '../../core/watch_connector.dart';
import '../exercises/exercises_provider.dart';

class RoutinesNotifier extends Notifier<List<Routine>> {
  late RoutinesRepository _repository;

  @override
  List<Routine> build() {
    _repository = ref.watch(routinesRepositoryProvider);
    if (!_repository.containsKey('r_4c')) {
      _preloadDefaults();
    }
    final loaded = _repository.getAllRoutines();
    Future.microtask(() => _syncToWatch(loaded));
    return loaded;
  }

  void _preloadDefaults() {
    for (var r in RoutinesRepository.defaultRoutines) {
      if (!_repository.containsKey(r.id)) {
        _repository.saveRoutine(r);
      }
    }
  }

  void addRoutine(String name, List<String> exerciseIds, {String? healthActivityType}) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoutine = Routine(
      id: newId, 
      name: name, 
      exerciseIds: exerciseIds, 
      healthActivityType: healthActivityType,
    );
    _repository.saveRoutine(newRoutine);
    state = _repository.getAllRoutines();
    _syncToWatch();
  }

  void updateRoutine(Routine updatedRoutine) {
    _repository.saveRoutine(updatedRoutine);
    state = _repository.getAllRoutines();
    _syncToWatch();
  }

  void deleteRoutine(String id) {
    _repository.deleteRoutine(id);
    state = _repository.getAllRoutines();
    _syncToWatch();
  }

  /// Sincronizza le schede con l'Apple Watch
  void _syncToWatch([List<Routine>? customRoutines]) {
    final watchConnector = ref.read(watchConnectorProvider);
    final exercises = ref.read(exercisesProvider);
    watchConnector.syncRoutinesToWatch(
      routines: customRoutines ?? state,
      exercises: exercises,
    );
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
    _syncToWatch();
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
    _syncToWatch();
  }

  void addExerciseToRoutine(String routineId, String exerciseId) {
    final routine = _repository.getRoutine(routineId);
    if (routine == null) return;
    if (!routine.exerciseIds.contains(exerciseId)) {
      final exIds = List<String>.from(routine.exerciseIds)..add(exerciseId);
      final updated = routine.copyWith(exerciseIds: exIds);
      _repository.saveRoutine(updated);
      state = _repository.getAllRoutines();
      _syncToWatch();
    }
  }
}

final routinesProvider = NotifierProvider<RoutinesNotifier, List<Routine>>(() => RoutinesNotifier());
