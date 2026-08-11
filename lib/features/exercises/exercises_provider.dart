import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/models.dart';

class ExercisesNotifier extends Notifier<List<Exercise>> {
  @override
  List<Exercise> build() {
    final box = Hive.box<Exercise>('exercises');
    if (box.isEmpty) {
      _preloadDefaults(box);
    }
    return box.values.toList();
  }

  void _preloadDefaults(Box<Exercise> box) {
    final defaults = [
      // Warmup
      Exercise(id: 'ex_1', name: 'mobilità lower', muscleGroup: 'Riscaldamento', metricType: MetricType.duration),
      Exercise(id: 'ex_2', name: 'mobilità upper', muscleGroup: 'Riscaldamento', metricType: MetricType.duration),
      Exercise(id: 'ex_3', name: 'serie di riscaldamento', muscleGroup: 'Riscaldamento'),
      // Core
      Exercise(id: 'ex_4', name: 'Plank', muscleGroup: 'Core', metricType: MetricType.duration),
      Exercise(id: 'ex_5', name: 'Crunch al cavo', muscleGroup: 'Core'),
      // Gambe / Glutei
      Exercise(id: 'ex_6', name: 'glute bridge', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_7', name: 'hip thrust', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_8', name: 'stacchi rumeni b-stance', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_9', name: 'stacchi rumeni', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_30', name: 'stacchi rumeni monopodalici su panca', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_31', name: 'affondi su rialzo posteriore multipower', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_10', name: 'affondi bulgari', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_11', name: 'kickback con extrarotazione', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_12', name: 'leg curl', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_13', name: 'step up', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_14', name: 'slanci laterali al cavo', muscleGroup: 'Gambe'),
      Exercise(id: 'ex_15', name: 'calf singolo in piedi', muscleGroup: 'Gambe'),
      // Schiena
      Exercise(id: 'ex_16', name: 'pulley', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_17', name: 'pulley a presa larga', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_18', name: 'Lat machine prona', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_19', name: 'lat machine con triangolo', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_20', name: 'Rematore singolo su panca', muscleGroup: 'Schiena'),
      Exercise(id: 'ex_21', name: 'hyperextension', muscleGroup: 'Schiena'),
      // Petto
      Exercise(id: 'ex_22', name: 'spinte con manubri su panca a 75°', muscleGroup: 'Petto'),
      // Spalle
      Exercise(id: 'ex_23', name: 'alzate laterali', muscleGroup: 'Spalle'),
      Exercise(id: 'ex_24', name: 'military press con bilanciere', muscleGroup: 'Spalle'),
      // Bicipiti
      Exercise(id: 'ex_25', name: 'Curl con bilanciere EZ', muscleGroup: 'Bicipiti'),
      Exercise(id: 'ex_26', name: 'Curl con manubri in piedi', muscleGroup: 'Bicipiti'),
      // Tricipiti
      Exercise(id: 'ex_27', name: 'push down corda', muscleGroup: 'Tricipiti'),
      Exercise(id: 'ex_28', name: 'french press seduta con manubrio', muscleGroup: 'Tricipiti'),
      Exercise(id: 'ex_29', name: 'triceps press cavo alto', muscleGroup: 'Tricipiti'),
    ];

    for (var ex in defaults) {
      box.put(ex.id, ex);
    }
  }

  void addExercise(String name, String muscleGroup, {bool isCustom = true, String notes = '', MetricType metricType = MetricType.reps}) {
    final box = Hive.box<Exercise>('exercises');
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newEx = Exercise(id: newId, name: name, muscleGroup: muscleGroup, isCustom: isCustom, notes: notes, metricType: metricType);
    box.put(newId, newEx);
    state = box.values.toList();
  }

  void editExercise(String id, String newName, String newNotes, {MetricType? metricType}) {
    final box = Hive.box<Exercise>('exercises');
    final existing = box.get(id);
    if (existing != null) {
      existing.name = newName;
      existing.notes = newNotes;
      if (metricType != null) existing.metricType = metricType;
      box.put(id, existing); // Save changes
      state = box.values.toList();
    }
  }
}

final exercisesProvider = NotifierProvider<ExercisesNotifier, List<Exercise>>(() {
  return ExercisesNotifier();
});
