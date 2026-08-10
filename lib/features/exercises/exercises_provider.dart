import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/models.dart';

final exercisesProvider = StateNotifierProvider<ExercisesNotifier, List<Exercise>>((ref) {
  return ExercisesNotifier();
});

class ExercisesNotifier extends StateNotifier<List<Exercise>> {
  ExercisesNotifier() : super([]) {
    _loadExercises();
  }

  void _loadExercises() {
    final box = Hive.box<Exercise>('exercises');
    
    if (box.isEmpty) {
      // Preload some default exercises
      _preloadDefaults(box);
    }
    
    state = box.values.toList();
  }

  void _preloadDefaults(Box<Exercise> box) {
    final defaults = [
      Exercise(id: '1', name: 'Panca Piana (Bilanciere)', muscleGroup: 'Chest'),
      Exercise(id: '2', name: 'Squat (Bilanciere)', muscleGroup: 'Legs'),
      Exercise(id: '3', name: 'Stacco da Terra (Bilanciere)', muscleGroup: 'Back'),
      Exercise(id: '4', name: 'Trazioni alla Sbarra', muscleGroup: 'Back'),
      Exercise(id: '5', name: 'Military Press (Bilanciere)', muscleGroup: 'Shoulders'),
    ];
    
    for (var ex in defaults) {
      box.put(ex.id, ex);
    }
  }

  void addExercise(String name, String muscleGroup) {
    final box = Hive.box<Exercise>('exercises');
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newEx = Exercise(id: newId, name: name, muscleGroup: muscleGroup, isCustom: true);
    box.put(newId, newEx);
    state = box.values.toList();
  }
}
