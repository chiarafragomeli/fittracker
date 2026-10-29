import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models.dart';
import '../../core/database/repositories_provider.dart';
import '../../core/database/exercises_repository.dart';

class ExercisesNotifier extends Notifier<List<Exercise>> {
  late ExercisesRepository _repository;

  @override
  List<Exercise> build() {
    _repository = ref.watch(exercisesRepositoryProvider);
    if (!_repository.containsKey('ex_46')) {
      _preloadDefaults();
    }
    return _getSortedExercises();
  }

  List<Exercise> _getSortedExercises() {
    final list = _repository.getAllExercises();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void _preloadDefaults() {
    for (var ex in ExercisesRepository.defaultExercises) {
      if (!_repository.containsKey(ex.id)) {
        _repository.saveExercise(ex);
      }
    }
  }

  void addExercise(String name, String muscleGroup, {bool isCustom = true, String notes = '', MetricType metricType = MetricType.reps}) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newEx = Exercise(id: newId, name: name, muscleGroup: muscleGroup, isCustom: isCustom, notes: notes, metricType: metricType);
    _repository.saveExercise(newEx);
    state = _getSortedExercises();
  }

  void editExercise(String id, String newName, String newNotes, {MetricType? metricType}) {
    final existing = _repository.getExercise(id);
    if (existing != null) {
      final updated = existing.copyWith(name: newName, notes: newNotes, metricType: metricType);
      _repository.saveExercise(updated);
      state = _getSortedExercises();
    }
  }

  void deleteExercise(String id) {
    _repository.deleteExercise(id);
    state = _getSortedExercises();
  }
}

final exercisesProvider = NotifierProvider<ExercisesNotifier, List<Exercise>>(() => ExercisesNotifier());
