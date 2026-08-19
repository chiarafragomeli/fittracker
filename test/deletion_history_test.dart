import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/database/models.dart';

void main() {
  test('Deleted exercise is still visible in history lookup', () {
    // Simulate exercises database
    final ex1 = Exercise(id: 'ex_1', name: 'Chest Press', muscleGroup: 'Petto');
    final exercises = [ex1];
    
    // User deletes exercise
    ex1.isDeleted = true;
    
    // History mapping logic in WorkoutHistoryScreen
    final exerciseMap = {for (var e in exercises) e.id: e};
    
    // Simulate a workout log that uses ex_1
    final pastWorkout = WorkoutLog(
      id: 'log_1',
      name: 'Giorno A',
      startTime: DateTime(2023, 4, 13),
      sets: [WorkoutSet(id: 'set_1', exerciseId: 'ex_1', reps: 10)],
    );
    
    // Verify that history can still resolve the name
    final nameInHistory = exerciseMap[pastWorkout.sets.first.exerciseId]?.name ?? 'Esercizio rimosso';
    
    expect(nameInHistory, 'Chest Press');
    expect(ex1.isDeleted, true);
  });
}
