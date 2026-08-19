import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/models.dart';

class RoutinesNotifier extends Notifier<List<Routine>> {
  @override
  List<Routine> build() {
    final box = Hive.box<Routine>('routines');
    if (box.isEmpty) {
      _preloadDefaults(box);
    }
    return box.values.toList();
  }

  void _preloadDefaults(Box<Routine> box) {
    final defaults = [
      // ---- SCHEDA 1 ----
      Routine(
        id: 'r_1a',
        name: 'Giorno 1A (Scheda 1 A)',
        // mobilità lower, glute bridge, Plank, serie risc., hip thrust, pulley,
        // stacchi rumeni b-stance, alzate laterali, hyperextension, calf singolo
        exerciseIds: [
          'ex_1',
          'ex_6',
          'ex_4',
          'ex_3',
          'ex_7',
          'ex_16',
          'ex_8',
          'ex_23',
          'ex_21',
          'ex_15',
        ],
      ),
      Routine(
        id: 'r_1b',
        name: 'Giorno 1B (Scheda 1 B)',
        // mobilità upper, Plank, serie risc., Lat machine prona,
        // spinte manubri 75°, pulley presa larga, Curl EZ, push down corda
        exerciseIds: [
          'ex_2',
          'ex_4',
          'ex_3',
          'ex_18',
          'ex_22',
          'ex_17',
          'ex_25',
          'ex_27',
        ],
      ),
      Routine(
        id: 'r_1c',
        name: 'Giorno 1C (Scheda 1 C)',
        // mobilità lower, glute bridge, Plank, serie risc.,
        // stacchi rumeni, hip thrust, affondi bulgari, kickback, leg curl
        exerciseIds: [
          'ex_1',
          'ex_6',
          'ex_4',
          'ex_3',
          'ex_9',
          'ex_7',
          'ex_10',
          'ex_11',
          'ex_12',
        ],
      ),
      // ---- SCHEDA 2 ----
      Routine(
        id: 'r_2a',
        name: 'Giorno 2A (Scheda 2 A)',
        // mobilità lower, mobilità upper, glute bridge, Plank, serie risc.,
        // stacchi rumeni, military press, step up, triceps press cavo alto, slanci laterali al cavo
        exerciseIds: [
          'ex_1',
          'ex_2',
          'ex_6',
          'ex_4',
          'ex_3',
          'ex_9',
          'ex_24',
          'ex_13',
          'ex_29',
          'ex_14',
        ],
      ),
      Routine(
        id: 'r_2b',
        name: 'Giorno 2B (Scheda 2 B)',
        // mobilità upper, Plank, serie risc., lat machine triangolo,
        // Rematore singolo, alzate laterali, Curl manubri, french press, Crunch al cavo
        exerciseIds: [
          'ex_2',
          'ex_4',
          'ex_3',
          'ex_19',
          'ex_20',
          'ex_23',
          'ex_26',
          'ex_28',
          'ex_5',
        ],
      ),
      Routine(
        id: 'r_2c',
        name: 'Giorno 2C (Scheda 2 C)',
        // mobilità lower, glute bridge, Plank, serie risc.,
        // hip thrust, stacchi rumeni monopodalici su panca,
        // affondi su rialzo posteriore multipower, hyperextension, kickback
        exerciseIds: [
          'ex_1',
          'ex_6',
          'ex_4',
          'ex_3',
          'ex_7',
          'ex_30',
          'ex_31',
          'ex_21',
          'ex_11',
        ],
      ),
    ];

    for (var r in defaults) {
      box.put(r.id, r);
    }
  }

  void addRoutine(String name, List<String> exerciseIds) {
    final box = Hive.box<Routine>('routines');
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoutine = Routine(id: newId, name: name, exerciseIds: exerciseIds);
    box.put(newId, newRoutine);
    state = box.values.toList();
  }

  void updateRoutine(String id, String newName, List<String> exerciseIds) {
    final box = Hive.box<Routine>('routines');
    final existing = box.get(id);
    if (existing == null) return;

    final updated = Routine(
      id: existing.id,
      name: newName,
      exerciseIds: exerciseIds,
      exerciseConfigs: existing.exerciseConfigs,
    );
    box.put(id, updated);
    state = box.values.toList();
  }

  void updateRoutineConfigs(
    String routineId,
    Map<String, ExerciseConfig> configs,
  ) {
    final box = Hive.box<Routine>('routines');
    final existing = box.get(routineId);
    if (existing == null) return;
    final updated = Routine(
      id: existing.id,
      name: existing.name,
      exerciseIds: existing.exerciseIds,
      exerciseConfigs: configs,
    );
    box.put(routineId, updated);
    state = box.values.toList();
  }
}

final routinesProvider = NotifierProvider<RoutinesNotifier, List<Routine>>(() {
  return RoutinesNotifier();
});
