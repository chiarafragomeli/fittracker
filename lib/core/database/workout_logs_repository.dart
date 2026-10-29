import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

class WorkoutLogsRepository {
  final Box<WorkoutLog> _box;

  WorkoutLogsRepository(this._box);

  List<WorkoutLog> getAllLogs() {
    return _box.values.toList();
  }

  WorkoutLog? getLog(String id) {
    return _box.get(id);
  }

  void saveLog(WorkoutLog log) {
    // Check if an existing log matches by id OR by routine name with start time within 3 minutes (deduplication)
    dynamic existingKey;
    for (final key in _box.keys) {
      final existing = _box.get(key);
      if (existing == null) continue;
      if (existing.id == log.id) {
        existingKey = key;
        break;
      }
      final timeDiff = existing.startTime.difference(log.startTime).inMinutes.abs();
      if (existing.name == log.name && timeDiff <= 3) {
        existingKey = key;
        break;
      }
    }

    if (existingKey != null) {
      // Overwrite/update existing record without creating a duplicate
      _box.put(existingKey, log);
    } else {
      _box.put(log.id, log);
    }
  }

  void deleteLog(String id) {
    _box.delete(id);
  }
}
