import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/database/models.dart';
import '../exercises/exercises_provider.dart';
import '../routines/routines_provider.dart';
import '../workout/workout_provider.dart';
import '../workout/active_workout_screen.dart';
import 'create_routine_screen.dart';

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const RoutineDetailScreen({super.key, required this.routine});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  // Local copy of configs, editable by user
  late Map<String, ExerciseConfig> _configs;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void didUpdateWidget(covariant RoutineDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine.id != widget.routine.id ||
        oldWidget.routine.exerciseIds.length !=
            widget.routine.exerciseIds.length) {
      _loadConfigs();
    }
  }

  void _loadConfigs() {
    _configs = {};
    for (final exId in widget.routine.exerciseIds) {
      _configs[exId] =
          widget.routine.exerciseConfigs[exId] ??
          ExerciseConfig(exerciseId: exId);
    }
  }

  void _saveConfigs() {
    // Save updated configs back to Hive via provider
    ref
        .read(routinesProvider.notifier)
        .updateRoutineConfigs(widget.routine.id, _configs);
  }

  void _showConfigSheet(String exId, String exName, Exercise? exercise) {
    final cfg = _configs[exId]!;
    int sets = cfg.defaultSets;
    int reps = cfg.defaultReps;
    int duration = cfg.defaultDuration;
    int rest = cfg.restSeconds;
    final isDuration = exercise?.metricType == MetricType.duration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isDuration)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⏱ Tempo',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // SERIE
              _ConfigRow(
                label: 'Serie',
                icon: Icons.repeat,
                value: sets,
                min: 1,
                max: 10,
                onDecrement: () =>
                    setSheetState(() => sets = (sets - 1).clamp(1, 10)),
                onIncrement: () =>
                    setSheetState(() => sets = (sets + 1).clamp(1, 10)),
              ),
              const SizedBox(height: 16),

              // REPS or DURATION
              if (isDuration)
                _ConfigRow(
                  label: 'Durata (sec)',
                  icon: Icons.timer,
                  value: duration,
                  min: 0,
                  max: 300,
                  step: 1,
                  onDecrement: () => setSheetState(
                    () => duration = (duration - 1).clamp(0, 300),
                  ),
                  onIncrement: () => setSheetState(
                    () => duration = (duration + 1).clamp(0, 300),
                  ),
                )
              else
                _ConfigRow(
                  label: 'Ripetizioni',
                  icon: Icons.fitness_center,
                  value: reps,
                  min: 1,
                  max: 50,
                  onDecrement: () =>
                      setSheetState(() => reps = (reps - 1).clamp(1, 50)),
                  onIncrement: () =>
                      setSheetState(() => reps = (reps + 1).clamp(1, 50)),
                ),
              const SizedBox(height: 16),

              // PAUSA
              _ConfigRow(
                label: 'Pausa (sec)',
                icon: Icons.timer_outlined,
                value: rest,
                min: 15,
                max: 300,
                step: 15,
                onDecrement: () =>
                    setSheetState(() => rest = (rest - 15).clamp(15, 300)),
                onIncrement: () =>
                    setSheetState(() => rest = (rest + 15).clamp(15, 300)),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _configs[exId] = ExerciseConfig(
                        exerciseId: exId,
                        defaultSets: sets,
                        defaultReps: reps,
                        defaultDuration: duration,
                        restSeconds: rest,
                      );
                    });
                    _saveConfigs();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Salva',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exercisesProvider);
    final exerciseMap = {for (var e in allExercises) e.id: e};
    final routines = ref.watch(routinesProvider);
    final currentRoutine = routines.firstWhere(
      (r) => r.id == widget.routine.id,
      orElse: () => widget.routine,
    );

    // Clean up any hard-deleted/orphaned exercise IDs
    final validExerciseIds = currentRoutine.exerciseIds
        .where((id) => exerciseMap.containsKey(id))
        .toList();

    // Make sure configs are updated if exercises were added or swapped
    for (final exId in validExerciseIds) {
      if (!_configs.containsKey(exId)) {
        _configs[exId] =
            currentRoutine.exerciseConfigs[exId] ??
            ExerciseConfig(exerciseId: exId);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRoutine.name, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreateRoutineScreen(routine: currentRoutine),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF5B8FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentRoutine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${validExerciseIds.length} esercizi  •  Tocca un esercizio per configurarlo',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: validExerciseIds.isEmpty
                ? const Center(child: Text('Nessun esercizio in questa scheda'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: validExerciseIds.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final exerciseIds = List<String>.from(validExerciseIds);
                      final item = exerciseIds.removeAt(oldIndex);
                      exerciseIds.insert(newIndex, item);

                      ref
                          .read(routinesProvider.notifier)
                          .updateRoutine(
                            currentRoutine.id,
                            currentRoutine.name,
                            exerciseIds,
                          );
                    },
                    proxyDecorator: (child, index, animation) => child,
                    itemBuilder: (context, index) {
                      final exId = validExerciseIds[index];
                      final ex = exerciseMap[exId]!;
                      final cfg = _configs[exId]!;

                      return GestureDetector(
                        key: ValueKey(exId),
                        onTap: () => _showConfigSheet(exId, ex.name, ex),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: index,
                                child: Container(
                                  padding: const EdgeInsets.only(
                                    right: 12,
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  color: Colors.transparent,
                                  child: const Icon(
                                    Icons.drag_handle,
                                    color: Colors.white24,
                                    size: 24,
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.15),
                                radius: 18,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Config summary chips
                                    Row(
                                      children: [
                                        _MiniChip(
                                          label: '${cfg.defaultSets} serie',
                                        ),
                                        const SizedBox(width: 6),
                                        _MiniChip(
                                          label:
                                              ex.metricType ==
                                                  MetricType.duration
                                              ? '${cfg.defaultDuration}s'
                                              : '${cfg.defaultReps} reps',
                                        ),
                                        const SizedBox(width: 6),
                                        _MiniChip(
                                          label: '${cfg.restSeconds}s pausa',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.textSecondaryColor,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Start button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Pass the updated routine with latest configs
                    final updatedRoutine = Routine(
                      id: currentRoutine.id,
                      name: currentRoutine.name,
                      exerciseIds: currentRoutine.exerciseIds,
                      exerciseConfigs: _configs,
                    );
                    ref
                        .read(workoutProvider.notifier)
                        .startWorkout(updatedRoutine);
                    // Ritorna alla home dove il MainNavigationScreen catturerà il tracking e lo mostrerà
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'AVVIA ALLENAMENTO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Small config row with +/- buttons ───────────────────────────────────────

class _ConfigRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final int step;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ConfigRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        Row(
          children: [
            _RoundButton(
              icon: Icons.remove,
              onTap: value <= min ? null : onDecrement,
            ),
            Container(
              width: 52,
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _RoundButton(
              icon: Icons.add,
              onTap: value >= max ? null : onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : Colors.white10,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppTheme.primaryColor : Colors.white24,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
