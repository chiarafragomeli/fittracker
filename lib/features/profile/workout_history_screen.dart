import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../core/database/models.dart';
import '../exercises/exercises_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  final String? filterMode; // 'today', 'week', 'month', or null for all
  const WorkoutHistoryScreen({super.key, this.filterMode});

  String get _title {
    switch (filterMode) {
      case 'today':
        return 'Allenamenti di Oggi';
      case 'week':
        return 'Allenamenti della Settimana';
      case 'month':
        return 'Allenamenti del Mese';
      default:
        return 'Storico Allenamenti';
    }
  }

  List<WorkoutLog> _filterLogs(List<WorkoutLog> logs) {
    if (filterMode == null) return logs;
    final now = DateTime.now();
    switch (filterMode) {
      case 'today':
        return logs
            .where(
              (l) =>
                  l.startTime.year == now.year &&
                  l.startTime.month == now.month &&
                  l.startTime.day == now.day,
            )
            .toList();
      case 'week':
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return logs
            .where(
              (l) =>
                  !l.startTime.isBefore(startOfWeek) &&
                  l.startTime.isBefore(endOfWeek),
            )
            .toList();
      case 'month':
        return logs
            .where(
              (l) =>
                  l.startTime.year == now.year &&
                  l.startTime.month == now.month,
            )
            .toList();
      default:
        return logs;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    final exerciseMap = {for (var e in exercises) e.id: e};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: Text(_title)),
      body: ValueListenableBuilder<Box<WorkoutLog>>(
        valueListenable: Hive.box<WorkoutLog>('workout_logs').listenable(),
        builder: (context, box, _) {
          final allLogs = box.values.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
          final logs = _filterLogs(allLogs);

          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'Nessun allenamento completato.',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final dateStr = DateFormat(
                'dd MMMM yyyy, HH:mm',
                'it_IT',
              ).format(log.startTime);

              // Group sets by exercise
              final Map<String, List<WorkoutSet>> setsByExercise = {};
              for (final set in log.sets) {
                if (!set.isCompleted) continue;
                setsByExercise.putIfAbsent(set.exerciseId, () => []).add(set);
              }

              Duration? duration;
              if (log.endTime != null) {
                duration = log.endTime!.difference(log.startTime);
              }

              return Dismissible(
                key: Key(log.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surfaceColor,
                      title: const Text('Elimina allenamento'),
                      content: const Text(
                        'Sei sicuro di voler eliminare questo allenamento?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Annulla',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Elimina',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  box.delete(log.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                log.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (duration != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Divider(height: 24, color: Colors.white10),

                        // Exercises summary
                        if (setsByExercise.isEmpty)
                          const Text(
                            'Nessuna serie completata',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 13,
                            ),
                          )
                        else
                          ...setsByExercise.entries.map((entry) {
                            final exId = entry.key;
                            final exSets = entry.value;
                            final exName =
                                exerciseMap[exId]?.name ?? 'Esercizio rimosso';

                            bool isDuration =
                                exerciseMap[exId]?.metricType ==
                                MetricType.duration;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    exName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                ...exSets.asMap().entries.map((setEntry) {
                                  final setIndex = setEntry.key + 1;
                                  final s = setEntry.value;

                                  final metricStr = isDuration
                                      ? '${s.durationSeconds}s'
                                      : '${s.reps} reps';
                                  final weightStr = s.weight > 0
                                      ? ' @ ${s.weight}kg'
                                      : '';

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Set $setIndex: $metricStr$weightStr ',
                                          style: const TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: AppTheme.successColor,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
