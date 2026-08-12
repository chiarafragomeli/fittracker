import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/database/models.dart';

void main() {
  group('Workout History Logic Tests', () {
    test('Logs are sorted chronologically descending', () {
      final log1 = WorkoutLog(id: '1', name: 'Log 1', startTime: DateTime(2023, 10, 1), sets: []);
      final log2 = WorkoutLog(id: '2', name: 'Log 2', startTime: DateTime(2023, 10, 3), sets: []);
      final log3 = WorkoutLog(id: '3', name: 'Log 3', startTime: DateTime(2023, 10, 2), sets: []);
      
      final logs = [log1, log2, log3];
      logs.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      expect(logs[0].id, '2'); // Oct 3
      expect(logs[1].id, '3'); // Oct 2
      expect(logs[2].id, '1'); // Oct 1
    });

    test('Sets are grouped correctly by exercise and max metrics are found', () {
      final sets = [
        WorkoutSet(id: 's1', exerciseId: 'ex1', weight: 50, reps: 8, isCompleted: true),
        WorkoutSet(id: 's2', exerciseId: 'ex1', weight: 60, reps: 6, isCompleted: true), // Max weight
        WorkoutSet(id: 's3', exerciseId: 'ex1', weight: 40, reps: 10, isCompleted: true), // Max reps
        WorkoutSet(id: 's4', exerciseId: 'ex2', weight: 0, reps: 0, durationSeconds: 45, isCompleted: true),
        WorkoutSet(id: 's5', exerciseId: 'ex2', weight: 0, reps: 0, durationSeconds: 60, isCompleted: true), // Max duration
        WorkoutSet(id: 's6', exerciseId: 'ex1', weight: 100, reps: 1, isCompleted: false), // Incomplete, should be ignored
      ];

      final Map<String, List<WorkoutSet>> setsByExercise = {};
      for (final set in sets) {
        if (!set.isCompleted) continue;
        setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
      }

      expect(setsByExercise.keys.length, 2);
      expect(setsByExercise['ex1']?.length, 3);
      expect(setsByExercise['ex2']?.length, 2);

      // Verify max calculation for ex1
      double maxWeight1 = 0;
      int maxReps1 = 0;
      for (final s in setsByExercise['ex1']!) {
        if (s.weight > maxWeight1) maxWeight1 = s.weight;
        if (s.reps > maxReps1) maxReps1 = s.reps;
      }
      expect(maxWeight1, 60.0);
      expect(maxReps1, 10);

      // Verify max calculation for ex2 (duration)
      int maxDuration = 0;
      for (final s in setsByExercise['ex2']!) {
        if (s.durationSeconds > maxDuration) maxDuration = s.durationSeconds;
      }
      expect(maxDuration, 60);
    });
  });
}
