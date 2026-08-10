import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'workout_provider.dart';
import '../../core/theme/theme.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutState = ref.watch(workoutProvider);
    final workout = workoutState.currentWorkout;

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Allenamento')),
        body: const Center(child: Text('Nessun allenamento attivo')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(workoutProvider.notifier).finishWorkout();
              context.pop();
            },
            child: const Text('Termina', style: TextStyle(color: AppTheme.successColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con cronometro e rest timer
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(workoutState.elapsedTime),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                if (workoutState.restTimer != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(workoutState.restTimer!),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // TODO: Implementare lista esercizi e set qui
                const Center(child: Text('Gli esercizi appariranno qui...')),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Aggiungi esercizio
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi Esercizio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
