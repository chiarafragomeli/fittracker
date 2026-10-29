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

  static final List<Routine> defaultRoutines = [
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
      name: 'Giorno 1C',
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
    // ---- SCHEDA 3 ----
    Routine(
      id: 'r_3a',
      name: 'Giorno 3A',
      exerciseIds: ['ex_1', 'ex_2', 'ex_3', 'ex_4', 'ex_7', 'ex_30', 'ex_19', 'ex_32', 'ex_33', 'ex_15'],
      exerciseConfigs: {
        'ex_1': ExerciseConfig(exerciseId: 'ex_1', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_2': ExerciseConfig(exerciseId: 'ex_2', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_3': ExerciseConfig(exerciseId: 'ex_3', defaultSets: 1, defaultReps: 25, defaultDuration: 30, restSeconds: 30),
        'ex_4': ExerciseConfig(exerciseId: 'ex_4', defaultSets: 1, defaultDuration: 45, restSeconds: 30),
        'ex_7': ExerciseConfig(
          exerciseId: 'ex_7',
          defaultSets: 3,
          defaultReps: 5,
          restSeconds: 120,
          routineNotes: "L'appoggio dietro le spalle deve essere più basso del ginocchio. Meglio sceglierlo 10 cm più basso che al limite del ginocchio.\nNota: +2/5 kg. Fai un fermo di 1 secondo in basso senza appoggiare a terra il bilanciere.",
        ),
        'ex_30': ExerciseConfig(
          exerciseId: 'ex_30',
          defaultSets: 3,
          defaultReps: 10,
          restSeconds: 120,
          routineNotes: 'Cerca di non mettere peso sulla gamba dietro, serve solo per equilibrio.',
        ),
        'ex_19': ExerciseConfig(
          exerciseId: 'ex_19',
          defaultSets: 4,
          defaultReps: 8,
          restSeconds: 120,
          routineNotes: 'Puoi usare il triangolo o la presa del pulley che hai nella tua palestra.',
        ),
        'ex_32': ExerciseConfig(exerciseId: 'ex_32', defaultSets: 3, defaultReps: 12, restSeconds: 90),
        'ex_33': ExerciseConfig(exerciseId: 'ex_33', defaultSets: 3, defaultReps: 11, restSeconds: 60),
        'ex_15': ExerciseConfig(
          exerciseId: 'ex_15',
          defaultSets: 3,
          defaultReps: 15,
          restSeconds: 30,
          routineNotes: 'Ripetizioni: max',
        ),
      },
    ),
    Routine(
      id: 'r_3b',
      name: 'Giorno 3B',
      exerciseIds: ['ex_2', 'ex_4', 'ex_34', 'ex_35', 'ex_36', 'ex_37', 'ex_23', 'ex_38', 'ex_39'],
      exerciseConfigs: {
        'ex_2': ExerciseConfig(exerciseId: 'ex_2', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_4': ExerciseConfig(exerciseId: 'ex_4', defaultSets: 1, defaultDuration: 45, restSeconds: 30),
        'ex_34': ExerciseConfig(
          exerciseId: 'ex_34',
          defaultSets: 5,
          defaultReps: 8,
          restSeconds: 120,
          routineNotes: 'Ripetizioni: max',
        ),
        'ex_35': ExerciseConfig(exerciseId: 'ex_35', defaultSets: 3, defaultReps: 8, restSeconds: 90),
        'ex_36': ExerciseConfig(exerciseId: 'ex_36', defaultSets: 3, defaultReps: 12, restSeconds: 90),
        'ex_37': ExerciseConfig(
          exerciseId: 'ex_37',
          defaultSets: 4,
          defaultReps: 8,
          restSeconds: 20,
          routineNotes: 'Superserie sup a (4 giri) con Alzate laterali.',
        ),
        'ex_23': ExerciseConfig(
          exerciseId: 'ex_23',
          defaultSets: 4,
          defaultReps: 10,
          restSeconds: 90,
          routineNotes: 'Superserie sup a (4 giri) con Alzate laterali seduta.',
        ),
        'ex_38': ExerciseConfig(exerciseId: 'ex_38', defaultSets: 4, defaultReps: 12, restSeconds: 60),
        'ex_39': ExerciseConfig(
          exerciseId: 'ex_39',
          defaultSets: 3,
          defaultReps: 10,
          restSeconds: 60,
          routineNotes: 'Ripetizioni: max',
        ),
      },
    ),
    Routine(
      id: 'r_3c',
      name: 'Giorno 3C',
      exerciseIds: ['ex_1', 'ex_3', 'ex_4', 'ex_9', 'ex_40', 'ex_10', 'ex_12', 'ex_14'],
      exerciseConfigs: {
        'ex_1': ExerciseConfig(exerciseId: 'ex_1', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_3': ExerciseConfig(exerciseId: 'ex_3', defaultSets: 1, defaultReps: 20, defaultDuration: 30, restSeconds: 30),
        'ex_4': ExerciseConfig(exerciseId: 'ex_4', defaultSets: 1, defaultDuration: 45, restSeconds: 30),
        'ex_9': ExerciseConfig(exerciseId: 'ex_9', defaultSets: 4, defaultReps: 8, restSeconds: 150),
        'ex_40': ExerciseConfig(
          exerciseId: 'ex_40',
          defaultSets: 3,
          defaultReps: 8,
          restSeconds: 120,
          routineNotes: "Il carico è poco più basso di quello che usi nell'hip thrust.\nNota: Fai 8 ripetizioni arrivando a cedimento, recupera 30 secondi e riparti arrivando a cedimento. Questa per ogni serie.",
        ),
        'ex_10': ExerciseConfig(exerciseId: 'ex_10', defaultSets: 3, defaultReps: 6, restSeconds: 120),
        'ex_12': ExerciseConfig(
          exerciseId: 'ex_12',
          defaultSets: 3,
          defaultReps: 8,
          restSeconds: 120,
          routineNotes: 'Se non trovi il macchinario del leg curl disteso, puoi fare quello da seduto o singolo in piedi.',
        ),
        'ex_14': ExerciseConfig(exerciseId: 'ex_14', defaultSets: 3, defaultReps: 12, restSeconds: 60),
      },
    ),
    // ---- SCHEDA 4 ----
    Routine(
      id: 'r_4a',
      name: 'Giorno 4A',
      exerciseIds: ['ex_1', 'ex_2', 'ex_3', 'ex_4', 'ex_41', 'ex_7', 'ex_22', 'ex_42', 'ex_14', 'ex_15'],
      exerciseConfigs: {
        'ex_1': ExerciseConfig(exerciseId: 'ex_1', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_2': ExerciseConfig(exerciseId: 'ex_2', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_3': ExerciseConfig(exerciseId: 'ex_3', defaultSets: 1, defaultReps: 25, defaultDuration: 30, restSeconds: 30),
        'ex_4': ExerciseConfig(exerciseId: 'ex_4', defaultSets: 1, defaultDuration: 45, restSeconds: 30),
        'ex_41': ExerciseConfig(exerciseId: 'ex_41', defaultSets: 4, defaultReps: 6, restSeconds: 150),
        'ex_7': ExerciseConfig(
          exerciseId: 'ex_7',
          defaultSets: 3,
          defaultReps: 7,
          restSeconds: 120,
          routineNotes: "L'appoggio dietro le spalle deve essere più basso del ginocchio. Meglio sceglierlo 10 cm più basso che al limite del ginocchio.",
        ),
        'ex_22': ExerciseConfig(exerciseId: 'ex_22', defaultSets: 3, defaultReps: 6, restSeconds: 120),
        'ex_42': ExerciseConfig(exerciseId: 'ex_42', defaultSets: 3, defaultReps: 8, restSeconds: 90),
        'ex_14': ExerciseConfig(exerciseId: 'ex_14', defaultSets: 3, defaultReps: 14, restSeconds: 90),
        'ex_15': ExerciseConfig(
          exerciseId: 'ex_15',
          defaultSets: 3,
          defaultReps: 15,
          restSeconds: 30,
          routineNotes: 'Ripetizioni: max',
        ),
      },
    ),
    Routine(
      id: 'r_4b',
      name: 'Giorno 4B',
      exerciseIds: ['ex_2', 'ex_43', 'ex_18', 'ex_44', 'ex_23', 'ex_27', 'ex_25', 'ex_45'],
      exerciseConfigs: {
        'ex_2': ExerciseConfig(exerciseId: 'ex_2', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_43': ExerciseConfig(exerciseId: 'ex_43', defaultSets: 2, defaultDuration: 30, restSeconds: 30),
        'ex_18': ExerciseConfig(exerciseId: 'ex_18', defaultSets: 4, defaultReps: 12, restSeconds: 120),
        'ex_44': ExerciseConfig(
          exerciseId: 'ex_44',
          defaultSets: 3,
          defaultReps: 6,
          restSeconds: 20,
          routineNotes: 'Superserie sup a (3 giri) con Alzate laterali.',
        ),
        'ex_23': ExerciseConfig(
          exerciseId: 'ex_23',
          defaultSets: 3,
          defaultReps: 10,
          restSeconds: 150,
          routineNotes: 'Superserie sup a (3 giri) con Military press con manubri.',
        ),
        'ex_27': ExerciseConfig(exerciseId: 'ex_27', defaultSets: 4, defaultReps: 8, restSeconds: 90),
        'ex_25': ExerciseConfig(exerciseId: 'ex_25', defaultSets: 4, defaultReps: 6, restSeconds: 90),
        'ex_45': ExerciseConfig(
          exerciseId: 'ex_45',
          defaultSets: 3,
          defaultReps: 15,
          restSeconds: 90,
          routineNotes: 'Ripetizioni: max',
        ),
      },
    ),
    Routine(
      id: 'r_4c',
      name: 'Giorno 4C',
      exerciseIds: ['ex_1', 'ex_3', 'ex_4', 'ex_8', 'ex_13', 'ex_46', 'ex_12', 'ex_11'],
      exerciseConfigs: {
        'ex_1': ExerciseConfig(exerciseId: 'ex_1', defaultSets: 1, defaultDuration: 30, restSeconds: 30),
        'ex_3': ExerciseConfig(exerciseId: 'ex_3', defaultSets: 1, defaultReps: 20, defaultDuration: 30, restSeconds: 30),
        'ex_4': ExerciseConfig(exerciseId: 'ex_4', defaultSets: 1, defaultDuration: 45, restSeconds: 30),
        'ex_8': ExerciseConfig(
          exerciseId: 'ex_8',
          defaultSets: 3,
          defaultReps: 6,
          restSeconds: 150,
          routineNotes: 'Nota: +1 kg',
        ),
        'ex_13': ExerciseConfig(
          exerciseId: 'ex_13',
          defaultSets: 3,
          defaultReps: 8,
          restSeconds: 120,
          routineNotes: 'Puoi svolgerlo posizionandoti anche su: panca piana, una panca e tenendoti a qualsiasi attrezzo, attrezzo per trazioni assistite.',
        ),
        'ex_46': ExerciseConfig(exerciseId: 'ex_46', defaultSets: 3, defaultReps: 8, restSeconds: 120),
        'ex_12': ExerciseConfig(
          exerciseId: 'ex_12',
          defaultSets: 3,
          defaultReps: 10,
          restSeconds: 90,
          routineNotes: 'Se non trovi il macchinario del leg curl disteso, puoi fare quello da seduto o singolo in piedi.',
        ),
        'ex_11': ExerciseConfig(exerciseId: 'ex_11', defaultSets: 2, defaultReps: 12, restSeconds: 90),
      },
    ),
  ];

  static void preloadDefaults(Box<Routine> box) {
    for (var r in defaultRoutines) {
      if (!box.containsKey(r.id)) {
        box.put(r.id, r);
      }
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
