import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class ExercisesRepository {
  final Box<Exercise> _box;

  ExercisesRepository(this._box);

  List<Exercise> getAllExercises() {
    return _box.values.toList();
  }

  Exercise? getExercise(String id) {
    return _box.get(id);
  }

  static final List<Exercise> defaultExercises = [
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
    // Scheda 3
    Exercise(id: 'ex_32', name: 'French press con bilanciere EZ', muscleGroup: 'Tricipiti'),
    Exercise(id: 'ex_33', name: 'Kickback al cavo', muscleGroup: 'Gambe'),
    Exercise(id: 'ex_34', name: 'Trazioni con elastico', muscleGroup: 'Schiena'),
    Exercise(id: 'ex_35', name: 'Rematore singolo al cavo', muscleGroup: 'Schiena'),
    Exercise(id: 'ex_36', name: 'Shoulder press machine', muscleGroup: 'Spalle'),
    Exercise(id: 'ex_37', name: 'Alzate laterali seduta', muscleGroup: 'Spalle'),
    Exercise(id: 'ex_38', name: 'Curl ai cavi alti', muscleGroup: 'Bicipiti'),
    Exercise(id: 'ex_39', name: 'Leg raise alla sbarra', muscleGroup: 'Core'),
    Exercise(id: 'ex_40', name: 'Kas bridge', muscleGroup: 'Gambe'),
    // Scheda 4
    Exercise(id: 'ex_41', name: 'Stacchi rumeni al multipower', muscleGroup: 'Gambe'),
    Exercise(id: 'ex_42', name: 'Rematore presa inversa al cavo', muscleGroup: 'Schiena'),
    Exercise(id: 'ex_43', name: 'Plank laterale', muscleGroup: 'Core', metricType: MetricType.duration),
    Exercise(id: 'ex_44', name: 'Military press con manubri', muscleGroup: 'Spalle'),
    Exercise(id: 'ex_45', name: 'Crunch su fitball', muscleGroup: 'Core'),
    Exercise(id: 'ex_46', name: 'Hyperextension gambe flesse', muscleGroup: 'Gambe'),
  ];

  static void preloadDefaults(Box<Exercise> box) {
    for (var ex in defaultExercises) {
      if (!box.containsKey(ex.id)) {
        box.put(ex.id, ex);
      }
    }
  }

  void saveExercise(Exercise exercise) {
    _box.put(exercise.id, exercise);
  }

  void deleteExercise(String id) {
    final existing = _box.get(id);
    if (existing != null) {
      final updated = existing.copyWith(isDeleted: true);
      _box.put(id, updated);
    }
  }

  bool get isEmpty => _box.isEmpty;

  bool containsKey(String key) => _box.containsKey(key);
}
