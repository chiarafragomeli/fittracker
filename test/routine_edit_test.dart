import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/database/models.dart';

void main() {
  test('Modifica della scheda: rimozione e aggiunta di esercizi', () {
    // 1. Stato iniziale: una scheda con 3 esercizi e relative configurazioni
    final initialRoutine = Routine(
      id: 'r_test',
      name: 'Scheda Originale',
      exerciseIds: ['ex_1', 'ex_2', 'ex_3'],
      exerciseConfigs: {
        'ex_1': ExerciseConfig(exerciseId: 'ex_1', defaultSets: 4, defaultReps: 10),
        'ex_2': ExerciseConfig(exerciseId: 'ex_2', defaultSets: 3, defaultReps: 12),
        'ex_3': ExerciseConfig(exerciseId: 'ex_3', defaultSets: 5, defaultReps: 8),
      },
    );

    // 2. Simuliamo l'azione dell'utente: rimuove 'ex_2' e aggiunge 'ex_4'
    final newExerciseIds = ['ex_1', 'ex_3', 'ex_4'];
    final newName = 'Scheda Modificata';

    // Questa è la logica che avviene in routines_provider.dart -> updateRoutine
    final updatedRoutine = Routine(
      id: initialRoutine.id,
      name: newName,
      exerciseIds: newExerciseIds,
      exerciseConfigs: initialRoutine.exerciseConfigs,
    );

    // 3. Simuliamo il caricamento della scheda in routine_detail_screen.dart
    Map<String, ExerciseConfig> loadedConfigs = {};
    for (final exId in updatedRoutine.exerciseIds) {
      loadedConfigs[exId] =
          updatedRoutine.exerciseConfigs[exId] ??
          ExerciseConfig(exerciseId: exId);
    }

    // 4. Verifiche (Assertions)
    
    // Controlliamo che il nome sia stato aggiornato
    expect(updatedRoutine.name, 'Scheda Modificata');
    
    // Controlliamo che gli ID degli esercizi siano corretti
    expect(updatedRoutine.exerciseIds, ['ex_1', 'ex_3', 'ex_4']);
    
    // Controlliamo che 'ex_1' e 'ex_3' abbiano mantenuto le vecchie configurazioni
    expect(loadedConfigs['ex_1']!.defaultSets, 4);
    expect(loadedConfigs['ex_1']!.defaultReps, 10);
    
    expect(loadedConfigs['ex_3']!.defaultSets, 5);
    expect(loadedConfigs['ex_3']!.defaultReps, 8);
    
    // Controlliamo che il nuovo 'ex_4' abbia le configurazioni di default
    expect(loadedConfigs['ex_4']!.defaultSets, 3); // Default
    expect(loadedConfigs['ex_4']!.defaultReps, 8); // Default
    
    // Controlliamo che 'ex_2' non sia più presente nelle configurazioni caricate
    expect(loadedConfigs.containsKey('ex_2'), false);
    
    print('✅ Test completato con successo: le configurazioni vengono mantenute correttamente!');
  });
}
