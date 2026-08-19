import 'dart:io';
import 'package:csv/csv.dart';

void main() {
  final csvData = File('assets/workouts.csv').readAsStringSync();
  List<List<dynamic>> rows = Csv().decode(csvData);
  print('Total rows: ${rows.length}');
  
  final monthMap = {
    'gen': '01', 'feb': '02', 'mar': '03', 'apr': '04', 'mag': '05', 'giu': '06',
    'lug': '07', 'ago': '08', 'set': '09', 'ott': '10', 'nov': '11', 'dic': '12'
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

  int successCount = 0;
  Map<String, int> failures = {};
  Set<String> titles = {};

  for (int i = 1; i < rows.length; i++) {
    var row = rows[i];
    if (row.length < 13) {
      failures['Length < 13: ${row.length}'] = (failures['Length < 13: ${row.length}'] ?? 0) + 1;
      continue;
    }
    String startTimeStr = row[1].toString();
    DateTime? startTime = parseDate(startTimeStr);
    if (startTime == null) {
      failures['Date null'] = (failures['Date null'] ?? 0) + 1;
      continue;
    }
    titles.add(row[0].toString() + " - " + startTimeStr);
    successCount++;
  }

  print('Success rows: $successCount');
  print('Failures: $failures');
  
  var sortedTitles = titles.toList()..sort();
  print('Total distinct workouts: ${sortedTitles.length}');
  for (int i=0; i<sortedTitles.length; i+=10) {
    print(sortedTitles[i]);
  }
}
