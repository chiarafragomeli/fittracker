import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/models.dart';

class ExercisesNotifier extends Notifier<List<Exercise>> {
  @override
  List<Exercise> build() {
    final box = Hive.box<Exercise>('exercises');
    if (!box.containsKey('ex_1')) {
      preloadDefaults(box);
    }
    return _getSortedExercises(box);
  }

  List<Exercise> _getSortedExercises(Box<Exercise> box) {
    final list = box.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  static void preloadDefaults(Box<Exercise> box) {
    final defaults = [
      // Warmup
      Exercise(
        id: 'ex_1',
        name: 'Mobilità lower',
        muscleGroup: 'Riscaldamento',
        metricType: MetricType.duration,
      ),
      Exercise(
        id: 'ex_2',
        name: 'Mobilità upper',
        muscleGroup: 'Riscaldamento',
        metricType: MetricType.duration,
      ),
      Exercise(
        id: 'ex_3',
        name: 'Ponte glutei',
        muscleGroup: 'Riscaldamento',
        metricType: MetricType.duration,
      ),
      // Core
      Exercise(
        id: 'ex_4',
        name: 'Plank',
        muscleGroup: 'Core',
        metricType: MetricType.duration,
      ),
      Exercise(id: 'ex_5', name: 'Crunch al cavo', muscleGroup: 'Core'),
      // Gambe / Glutei
      Exercise(id: 'ex_7', name: 'Hip thrust', muscleGroup: 'Gambe'),
      Exercise(
        id: 'ex_8',
        name: 'Stacchi rumeni b-stance',
        muscleGroup: 'Gambe',
      ),
      Exercise(id: 'ex_9', name: 'Stacchi rumeni', muscleGroup: 'Gambe'),
      Exercise(
        id: 'ex_30',
        name: 'Stacchi rumeni monopodalici su panca',
        muscleGroup: 'Gambe',
      ),
      Exercise(
        id: 'ex_31',
        name: 'Affondi su rialzo posteriore multipower',
        muscleGroup: 'Gambe',
      ),
      Exercise(id: 'ex_10', name: 'Affondi bulgari', muscleGroup: 'Gambe'),
      Exercise(
        id: 'ex_11',
        name: 'Kickback con extrarotazione',
        muscleGroup: 'Gambe',
      ),
      Exercise(id: 'ex_12', name: 'Leg curl', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_13', name: 'Step up', muscleGroup: 'Gambe'),
      Exercise(
        id: 'ex_14',
        name: 'Slanci laterali al cavo',
        muscleGroup: 'Gambe',
      ),
      Exercise(
        id: 'ex_15',
        name: 'Calf singolo in piedi',
        muscleGroup: 'Gambe',
      ),
      // Schiena
      Exercise(id: 'ex_16', name: 'Pulley', muscleGroup: 'Schiena'),
      Exercise(
        id: 'ex_17',
        name: 'Pulley a presa larga',
        muscleGroup: 'Schiena',
      ),
      Exercise(id: 'ex_18', name: 'Lat machine prona', muscleGroup: 'Schiena'),
      Exercise(
        id: 'ex_19',
        name: 'Lat machine con triangolo',
        muscleGroup: 'Schiena',
      ),
      Exercise(
        id: 'ex_20',
        name: 'Rematore singolo su panca',
        muscleGroup: 'Schiena',
      ),
      Exercise(id: 'ex_21', name: 'Hyperextension', muscleGroup: 'Schiena'),
      // Petto
      Exercise(
        id: 'ex_22',
        name: 'Spinte con manubri su panca a 75°',
        muscleGroup: 'Petto',
      ),
      // Spalle
      Exercise(id: 'ex_23', name: 'Alzate laterali', muscleGroup: 'Spalle'),
      Exercise(
        id: 'ex_24',
        name: 'Military press con bilanciere',
        muscleGroup: 'Spalle',
      ),
      // Bicipiti
      Exercise(
        id: 'ex_25',
        name: 'Curl con bilanciere EZ',
        muscleGroup: 'Bicipiti',
      ),
      Exercise(
        id: 'ex_26',
        name: 'Curl con manubri in piedi',
        muscleGroup: 'Bicipiti',
      ),
      // Tricipiti
      Exercise(id: 'ex_27', name: 'Push down corda', muscleGroup: 'Tricipiti'),
      Exercise(
        id: 'ex_28',
        name: 'French press seduta con manubrio',
        muscleGroup: 'Tricipiti',
      ),
      Exercise(
        id: 'ex_29',
        name: 'Triceps press cavo alto',
        muscleGroup: 'Tricipiti',
      ),
    ];

    for (var ex in defaults) {
      box.put(ex.id, ex);
    }
  }

  void addExercise(
    String name,
    String muscleGroup, {
    bool isCustom = true,
    String notes = '',
    MetricType metricType = MetricType.reps,
  }) {
    final box = Hive.box<Exercise>('exercises');
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newEx = Exercise(
      id: newId,
      name: name,
      muscleGroup: muscleGroup,
      isCustom: isCustom,
      notes: notes,
      metricType: metricType,
    );
    box.put(newId, newEx);
    state = _getSortedExercises(box);
  }

  void editExercise(
    String id,
    String newName,
    String newNotes, {
    MetricType? metricType,
  }) {
    final box = Hive.box<Exercise>('exercises');
    final existing = box.get(id);
    if (existing != null) {
      existing.name = newName;
      existing.notes = newNotes;
      if (metricType != null) existing.metricType = metricType;
      box.put(id, existing); // Save changes
      state = _getSortedExercises(box);
    }
  }

  void deleteExercise(String id) {
    final box = Hive.box<Exercise>('exercises');
    final existing = box.get(id);
    if (existing != null) {
      existing.isDeleted = true;
      box.put(id, existing);
      state = _getSortedExercises(box);
    }
  }
}

final exercisesProvider = NotifierProvider<ExercisesNotifier, List<Exercise>>(
  () {
    return ExercisesNotifier();
  },
);
