import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/models.dart';
import '../../core/database/repositories_provider.dart';
import '../../core/database/exercises_repository.dart';

class ExercisesNotifier extends Notifier<List<Exercise>> {
  late ExercisesRepository _repository;

  @override
  List<Exercise> build() {
    _repository = ref.watch(exercisesRepositoryProvider);
    if (!_repository.containsKey('ex_1')) {
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
    final defaults = [
      Exercise(id: 'ex_1', name: 'Mobilità lower', muscleGroup: 'Riscaldamento', metricType: MetricType.duration),
      Exercise(id: 'ex_2', name: 'Mobilità upper', muscleGroup: 'Riscaldamento', metricType: MetricType.duration),
      Exercise(id: 'ex_3', name: 'Ponte glutei', muscleGroup: 'Riscaldamento', metricType: MetricType.duration),
      Exercise(id: 'ex_4', name: 'Plank', muscleGroup: 'Core', metricType: MetricType.duration),
      Exercise(id: 'ex_5', name: 'Crunch al cavo', muscleGroup: 'Core'),
      Exercise(id: 'ex_7', name: 'Hip thrust', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_8', name: 'Stacchi rumeni b-stance', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_9', name: 'Stacchi rumeni', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_30', name: 'Stacchi rumeni monopodalici su panca', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_31', name: 'Affondi su rialzo posteriore multipower', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_10', name: 'Affondi bulgari', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_11', name: 'Kickback con extrarotazione', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_12', name: 'Leg curl', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_13', name: 'Step up', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_14', name: 'Slanci laterali al cavo', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_15', name: 'Calf singolo in piedi', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_16', name: 'Pulley', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_17', name: 'Pulley a presa larga', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_18', name: 'Lat machine prona', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_19', name: 'Lat machine con triangolo', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_20', name: 'Rematore singolo su panca', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_21', name: 'Hyperextension', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_22', name: 'Spinte con manubri su panca a 75°', muscleGroup: 'Petto'),
      Exercise(id: 'ex_23', name: 'Alzate laterali', muscleGroup: 'Spalle'),
      Exercise(id: 'ex_24', name: 'Military press con bilanciere', muscleGroup: 'Spalle'),
      Exercise(id: 'ex_25', name: 'Curl con bilanciere EZ', muscleGroup: 'Bicipiti'),
      Exercise(id: 'ex_26', name: 'Curl con manubri in piedi', muscleGroup: 'Bicipiti'),
      Exercise(id: 'ex_27', name: 'Push down corda', muscleGroup: 'Tricipiti'),
      Exercise(id: 'ex_28', name: 'French press seduta con manubrio', muscleGroup: 'Tricipiti'),
      Exercise(id: 'ex_29', name: 'Triceps press cavo alto', muscleGroup: 'Tricipiti'),
    ];
    for (var ex in defaults) {
      _repository.saveExercise(ex);
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
