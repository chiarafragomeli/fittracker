import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../core/database/models.dart';
import '../exercises/exercises_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);
    final exerciseMap = {for (var e in exercises) e.id: e};

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Storico Allenamenti'),
      ),
      body: ValueListenableBuilder<Box<WorkoutLog>>(
        valueListenable: Hive.box<WorkoutLog>('workout_logs').listenable(),
        builder: (context, box, _) {
          final logs = box.values.toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));

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
              final dateStr = DateFormat('dd MMMM yyyy, HH:mm', 'it_IT').format(log.startTime);
              
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

              return Container(
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
                                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Divider(height: 24, color: Colors.white10),
                      
                      // Exercises summary
                      if (setsByExercise.isEmpty)
                        const Text('Nessuna serie completata', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13))
                      else
                        ...setsByExercise.entries.map((entry) {
                          final exId = entry.key;
                          final exSets = entry.value;
                          final exName = exerciseMap[exId]?.name ?? 'Esercizio rimosso';
                          
                          // Calculate max weight / metric
                          double maxWeight = 0;
                          int maxMetric = 0;
                          bool isDuration = exerciseMap[exId]?.metricType == MetricType.duration;
                          
                          for (final s in exSets) {
                            if (s.weight > maxWeight) maxWeight = s.weight;
                            final metric = isDuration ? s.durationSeconds : s.reps;
                            if (metric > maxMetric) maxMetric = metric;
                          }
                          
                          final weightStr = maxWeight > 0 ? ' @ ${maxWeight}kg' : '';
                          final metricStr = isDuration ? '${maxMetric}s' : '${maxMetric} reps';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Text('${exSets.length}x ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                Expanded(child: Text(exName, style: const TextStyle(fontWeight: FontWeight.w500))),
                                Text('Max: $metricStr$weightStr', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                              ],
                            ),
                          );
                        }),
                    ],
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
