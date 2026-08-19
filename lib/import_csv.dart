import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'core/database/models.dart';

Future<void> importWorkoutsFromCsv() async {
  final box = Hive.box<WorkoutLog>('workout_logs');
  final exercisesBox = Hive.box<Exercise>('exercises');

  print('Reading workouts.csv...');
  String csvData;
  try {
    csvData = await rootBundle.loadString('assets/workouts.csv');
  } catch (e) {
    print('Could not load assets/workouts.csv');
    return;
  }

  List<List<dynamic>> rows = Csv().decode(csvData);
  if (rows.isEmpty) return;

  Map<String, Exercise> exerciseMap = {};
  for (var ex in exercisesBox.values) {
    exerciseMap[ex.name] = ex;
  }

  final monthMap = {
    'gen': '01',
    'feb': '02',
    'mar': '03',
    'apr': '04',
    'mag': '05',
    'giu': '06',
    'lug': '07',
    'ago': '08',
    'set': '09',
    'ott': '10',
    'nov': '11',
    'dic': '12',
  };

  DateTime? parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split(', ');
      final dateParts = parts[0].split(' ');
      final day = dateParts[0].padLeft(2, '0');
      final monthStr = dateParts[1].toLowerCase();
      final month = monthMap[monthStr] ?? '01';
      final year = dateParts[2];
      final time = parts[1];
      return DateTime.parse('$year-$month-${day}T$time:00');
    } catch (e) {
      print('Error parsing date: $dateStr');
      return null;
    }
  }

  Map<String, WorkoutLog> logsByGroup = {};
  final uuid = const Uuid();

  for (int i = 1; i < rows.length; i++) {
    var row = rows[i];
    if (row.length < 13) continue;

    String title = row[0].toString();
    String startTimeStr = row[1].toString();
    String endTimeStr = row[2].toString();
    String exerciseTitle = row[4].toString();

    double weightKg = double.tryParse(row[9].toString()) ?? 0.0;
    int reps = int.tryParse(row[10].toString()) ?? 0;
    int durationSecs = int.tryParse(row[12].toString()) ?? 0;

    DateTime? startTime = parseDate(startTimeStr);
    DateTime? endTime = parseDate(endTimeStr);

    if (startTime == null) continue;

    String groupKey = '${title}_$startTimeStr';

    if (!exerciseMap.containsKey(exerciseTitle)) {
      final newEx = Exercise(
        id: uuid.v4(),
        name: exerciseTitle,
        muscleGroup: 'Altro',
        metricType: durationSecs > 0 && reps == 0
            ? MetricType.duration
            : MetricType.reps,
      );
      exercisesBox.put(newEx.id, newEx);
      exerciseMap[exerciseTitle] = newEx;
    }

    Exercise ex = exerciseMap[exerciseTitle]!;

    WorkoutSet set = WorkoutSet(
      id: uuid.v4(),
      exerciseId: ex.id,
      weight: weightKg,
      reps: reps,
      durationSeconds: durationSecs,
      isCompleted: true,
    );

    if (!logsByGroup.containsKey(groupKey)) {
      logsByGroup[groupKey] = WorkoutLog(
        id: uuid.v4(),
        name: title,
        startTime: startTime,
        endTime: endTime,
        sets: [],
      );
    }

    logsByGroup[groupKey]!.sets.add(set);
  }

  var logsList = logsByGroup.values.toList();
  logsList.sort((a, b) => a.startTime.compareTo(b.startTime));

  int importedCount = 0;
  for (var log in logsList) {
    // Delete any existing log with the exactly same start time to overwrite truncated ones
    final existingKeys = box.keys.where((k) {
      final existingLog = box.get(k);
      return existingLog != null && existingLog.startTime == log.startTime;
    }).toList();

    if (existingKeys.isNotEmpty) {
      for (var k in existingKeys) {
        await box.delete(k);
      }
    }

    await box.put(log.id, log);
    importedCount++;
  }

  print('Imported $importedCount workouts from CSV.');
}
