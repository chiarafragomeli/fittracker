import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../database/models.dart';

class CsvExportService {
  static const MethodChannel _channel = MethodChannel('gym_tracker/watch');

  /// Genera un file CSV compatibile con l'importazione di Hevy (formato Strong CSV)
  /// e apre il foglio di condivisione nativo iOS.
  static Future<bool> exportWorkoutsForHevy({
    required List<WorkoutLog> logs,
    required List<Exercise> exercises,
    String fileNamePrefix = 'hevy_export',
  }) async {
    if (logs.isEmpty) return false;

    final exerciseMap = {for (final e in exercises) e.id: e};
    final sortedLogs = List<WorkoutLog>.from(logs)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final buffer = StringBuffer();
    // Header ufficiale richiesto da Hevy ("Import Strong CSV")
    buffer.writeln(
      'Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,RPE,Notes,Workout Notes',
    );

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    for (final log in sortedLogs) {
      final dateStr = dateFormat.format(log.startTime);
      final workoutName = log.name.isNotEmpty ? log.name : 'Workout';
      final durationStr = _formatStrongDuration(log.startTime, log.endTime);

      // Raggruppa le serie completate per esercizio mantenendo l'ordine
      final Map<String, List<WorkoutSet>> setsByExercise = {};
      for (final s in log.sets) {
        if (!s.isCompleted) continue;
        setsByExercise.putIfAbsent(s.exerciseId, () => []).add(s);
      }

      for (final entry in setsByExercise.entries) {
        final ex = exerciseMap[entry.key];
        final exName = ex?.name ?? 'Exercise';
        final isDuration = ex?.metricType == MetricType.duration;
        final sets = entry.value;

        for (int i = 0; i < sets.length; i++) {
          final s = sets[i];
          final setOrder = i + 1;
          final weightStr = s.weight == s.weight.roundToDouble()
              ? s.weight.toInt().toString()
              : s.weight.toString();
          final repsStr = isDuration ? '0' : s.reps.toString();
          final secondsStr = isDuration ? s.durationSeconds.toString() : '0';

          final row = [
            _escape(dateStr),
            _escape(workoutName),
            _escape(durationStr),
            _escape(exName),
            setOrder.toString(),
            weightStr,
            repsStr,
            '0',
            secondsStr,
            '',
            '',
            '',
          ].join(',');

          buffer.writeln(row);
        }
      }
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final safePrefix = fileNamePrefix
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .toLowerCase();
    final file = File('${tempDir.path}/${safePrefix}_$timestamp.csv');
    await file.writeAsString(buffer.toString());

    await _channel.invokeMethod('shareFile', {'path': file.path});
    return true;
  }

  static String _formatStrongDuration(DateTime start, DateTime? end) {
    if (end == null) return '45m';
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}m';
    return '${diff.inSeconds.clamp(1, 59)}s';
  }

  static String _escape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
