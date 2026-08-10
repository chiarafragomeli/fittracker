import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/database/models.dart';

final routinesProvider = StateNotifierProvider<RoutinesNotifier, List<Routine>>((ref) {
  return RoutinesNotifier();
});

class RoutinesNotifier extends StateNotifier<List<Routine>> {
  RoutinesNotifier() : super([]) {
    _loadRoutines();
  }

  void _loadRoutines() {
    final box = Hive.box<Routine>('routines');
    state = box.values.toList();
  }

  void addRoutine(String name, List<String> exerciseIds) {
    final box = Hive.box<Routine>('routines');
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoutine = Routine(id: newId, name: name, exerciseIds: exerciseIds);
    box.put(newId, newRoutine);
    state = box.values.toList();
  }
}
