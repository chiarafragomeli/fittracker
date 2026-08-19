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
    _box.put(log.id, log);
  }

  void deleteLog(String id) {
    _box.delete(id);
  }
}
