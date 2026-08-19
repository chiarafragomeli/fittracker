import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/database/models.dart';
import '../exercises/exercises_provider.dart';
import '../workout/workout_provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late Map<String, List<Map<String, dynamic>>> _sets;
  OverlayEntry? _restDoneOverlay;

  // Per-set exercise timer tracking: key = "exId_setIndex"
  final Map<String, Timer> _exerciseTimers = {};
  final Map<String, int> _exerciseTimerSeconds = {};
  final Map<String, bool> _exerciseTimerRunning = {};

  @override
  void initState() {
    super.initState();
    final stateSets = ref.read(workoutProvider).activeSets;
    if (stateSets != null && stateSets.isNotEmpty) {
      _sets = Map<String, List<Map<String, dynamic>>>.from(
        stateSets.map((k, v) => MapEntry(k, List<Map<String, dynamic>>.from(
          v.map((set) => Map<String, dynamic>.from(set))
        )))
      );
    } else {
      _sets = {};
      final allExercises = ref.read(exercisesProvider);
      final exerciseMap = {for (var e in allExercises) e.id: e};
      for (final exId in widget.routine.exerciseIds) {
        final cfg = widget.routine.exerciseConfigs[exId] ?? ExerciseConfig(exerciseId: exId);
        final exercise = exerciseMap[exId];
        final isDuration = exercise?.metricType == MetricType.duration;
        _sets[exId] = List.generate(
          cfg.defaultSets,
          (_) => {
            'weight': 0.0,
            'done': false,
            if (isDuration) 'duration': cfg.defaultDuration else 'reps': cfg.defaultReps,
            'metricType': isDuration ? 'duration' : 'reps',
          },
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(workoutProvider.notifier).updateActiveSets(_sets);
      });
    }
  }

  void _saveSetsToProvider() {
    ref.read(workoutProvider.notifier).updateActiveSets(_sets);
  }

  @override
  void dispose() {
    _restDoneOverlay?.remove();
    for (final t in _exerciseTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  String _formatSeconds(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showRestDoneOverlay() {
    _restDoneOverlay?.remove();
    _restDoneOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 56,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            builder: (_, v, child) => Opacity(opacity: v, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppTheme.successColor.withValues(alpha: 0.4), blurRadius: 20)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 22),
                  SizedBox(width: 12),
                  Text('⏱️ Pausa terminata! Riprendi.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_restDoneOverlay!);
    Future.delayed(const Duration(seconds: 3), () {
      _restDoneOverlay?.remove();
      _restDoneOverlay = null;
    });
  }

  void _addSet(String exId, Exercise ex) {
    setState(() {
      final cfg = widget.routine.exerciseConfigs[exId] ?? ExerciseConfig(exerciseId: exId);
      final isDuration = ex.metricType == MetricType.duration;
      _sets[exId]!.add({
        'weight': 0.0,
        'done': false,
        if (isDuration) 'duration': cfg.defaultDuration else 'reps': cfg.defaultReps,
        'metricType': isDuration ? 'duration' : 'reps',
      });
    });
    _saveSetsToProvider();
  }

  void _removeSet(String exId) {
    if ((_sets[exId]?.length ?? 0) <= 1) return;
    final lastIdx = _sets[exId]!.length - 1;
    final timerKey = '${exId}_$lastIdx';
    _exerciseTimers[timerKey]?.cancel();
    _exerciseTimers.remove(timerKey);
    _exerciseTimerSeconds.remove(timerKey);
    _exerciseTimerRunning.remove(timerKey);
    setState(() => _sets[exId]!.removeLast());
    _saveSetsToProvider();
  }

  void _toggleSetDone(String exId, int i) {
    final wasChecked = _sets[exId]![i]['done'] as bool;
    setState(() => _sets[exId]![i]['done'] = !wasChecked);
    _saveSetsToProvider();

    // Stop any running exercise timer for this set
    final timerKey = '${exId}_$i';
    _exerciseTimers[timerKey]?.cancel();
    _exerciseTimerRunning[timerKey] = false;

    if (!wasChecked) {
      // Checking → start rest timer
      final cfg = widget.routine.exerciseConfigs[exId] ?? ExerciseConfig(exerciseId: exId);
      ref.read(workoutProvider.notifier).startRestTimer(Duration(seconds: cfg.restSeconds));
    } else {
      // Un-checking → cancel and reset timer, also reset exercise timer
      ref.read(workoutProvider.notifier).cancelRestTimer();
      _exerciseTimerSeconds[timerKey] = 0;
    }
  }

  // Exercise timer controls (for duration-based exercises)
  void _startExerciseTimer(String exId, int setIndex) {
    final timerKey = '${exId}_$setIndex';
    if (_exerciseTimerRunning[timerKey] == true) return; // Already running

    _exerciseTimerSeconds[timerKey] ??= 0;
    _exerciseTimerRunning[timerKey] = true;

    _exerciseTimers[timerKey] = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _exerciseTimerSeconds[timerKey] = (_exerciseTimerSeconds[timerKey] ?? 0) + 1;
          _sets[exId]![setIndex]['duration'] = _exerciseTimerSeconds[timerKey];
        });
        _saveSetsToProvider();
      }
    });
  }

  void _stopExerciseTimer(String exId, int setIndex) {
    final timerKey = '${exId}_$setIndex';
    _exerciseTimers[timerKey]?.cancel();
    _exerciseTimerRunning[timerKey] = false;
    setState(() {});
  }

  Future<void> _handleFinish() async {
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Termina allenamento'),
        content: const Text('Vuoi salvare i progressi o abbandonare senza salvare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbandona', style: TextStyle(color: AppTheme.errorColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (save == null) return;

    // Cancel all exercise timers
    for (final t in _exerciseTimers.values) {
      t.cancel();
    }

    if (save) {
      ref.read(workoutProvider.notifier).finishWorkout();
    } else {
      ref.read(workoutProvider.notifier).discardWorkout();
    }
  }

  Map<String, dynamic>? _getExerciseHistory(String exId, bool isDuration) {
    if (!Hive.isBoxOpen('workout_logs')) return null;
    final box = Hive.box<WorkoutLog>('workout_logs');
    final logs = box.values.toList().reversed;
    
    for (final log in logs) {
      final sets = log.sets.where((s) => s.exerciseId == exId && s.isCompleted).toList();
      if (sets.isNotEmpty) {
        double maxWeight = 0;
        int maxMetric = 0;
        for (final s in sets) {
          if (s.weight > maxWeight) maxWeight = s.weight;
          final metric = isDuration ? s.durationSeconds : s.reps;
          if (metric > maxMetric) maxMetric = metric;
        }
        return {
          'date': log.startTime,
          'maxWeight': maxWeight,
          'maxMetric': maxMetric,
          'totalSets': sets.length,
        };
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutProvider);

    // Show overlay when rest timer finishes
    ref.listen<WorkoutState>(workoutProvider, (prev, next) {
      if (next.restTimerJustFinished && !(prev?.restTimerJustFinished ?? false)) {
        _showRestDoneOverlay();
        ref.read(workoutProvider.notifier).acknowledgeRestFinished();
      }
    });

    final allExercises = ref.watch(exercisesProvider);
    final exerciseMap = {for (var e in allExercises) e.id: e};

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 28),
          onPressed: () => ref.read(workoutProvider.notifier).minimizeWorkout(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.routine.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 13, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(_formatDuration(workoutState.elapsedTime),
                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor)),
            ]),
          ],
        ),
        actions: [
          if (workoutState.restTimer != null && workoutState.restTimer!.inSeconds > 0)
            GestureDetector(
              onTap: () => ref.read(workoutProvider.notifier).cancelRestTimer(),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bedtime_outlined, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(_formatDuration(workoutState.restTimer!),
                      style: const TextStyle(
                          color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.close, size: 12, color: AppTheme.primaryColor),
                ]),
              ),
            ),
          TextButton(
            onPressed: _handleFinish,
            child: const Text('Fine',
                style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.routine.exerciseIds.length,
        itemBuilder: (context, exIndex) {
          final exId = widget.routine.exerciseIds[exIndex];
          final ex = exerciseMap[exId];
          if (ex == null) return const SizedBox.shrink();
          final sets = _sets[exId] ?? [];
          final cfg = widget.routine.exerciseConfigs[exId];
          final hasNotes = (ex.notes.isNotEmpty) || (cfg?.routineNotes.isNotEmpty ?? false);
          final isDuration = ex.metricType == MetricType.duration;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppTheme.surfaceColor, borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Text('${exIndex + 1}',
                            style: const TextStyle(
                                color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(ex.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Row(children: [
                          Text(ex.muscleGroup,
                              style: const TextStyle(
                                  color: AppTheme.textSecondaryColor, fontSize: 12)),
                          if (isDuration) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('⏱ Tempo', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ]),
                      ]),
                    ),
                  ]),

                  // Notes
                  if (hasNotes) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              [
                                if (cfg?.routineNotes.isNotEmpty ?? false) cfg!.routineNotes,
                                if (ex.notes.isNotEmpty) ex.notes,
                              ].join('\n'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Previous history
                  Builder(
                    builder: (context) {
                      final history = _getExerciseHistory(exId, isDuration);
                      if (history == null) return const SizedBox.shrink();
                      
                      final dateStr = DateFormat('dd MMM yyyy', 'it_IT').format(history['date'] as DateTime);
                      final metricStr = isDuration ? '${history['maxMetric']}s' : '${history['maxMetric']} reps';
                      final weightStr = history['maxWeight'] > 0 ? ' @ ${history['maxWeight']}kg' : '';
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 14, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ultima volta ($dateStr): ${history['totalSets']} set | Max: $metricStr$weightStr',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Table header - different for reps vs duration
                  if (sets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(children: [
                        const SizedBox(width: 36,
                            child: Text('Set', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12))),
                        Expanded(child: Text('Kg', textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12))),
                        Expanded(child: Text(isDuration ? 'Tempo' : 'Reps', textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12))),
                        const SizedBox(width: 44, child: Text('✓', textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12))),
                      ]),
                    ),

                  // Set rows
                  ...sets.asMap().entries.map((entry) {
                    final i = entry.key;
                    final set = entry.value;
                    final done = set['done'] as bool;
                    final timerKey = '${exId}_$i';
                    final isTimerRunning = _exerciseTimerRunning[timerKey] == true;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                      decoration: BoxDecoration(
                        color: done ? AppTheme.successColor.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        SizedBox(
                          width: 36,
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: done ? AppTheme.successColor : Colors.white70)),
                        ),
                        // Weight field (same for both types)
                        Expanded(
                          child: _NumberField(
                            value: set['weight'],
                            isDecimal: true,
                            onChanged: (v) {
                              setState(() => _sets[exId]![i]['weight'] = v);
                              _saveSetsToProvider();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Reps field or Duration timer
                        Expanded(
                          child: isDuration
                              ? _DurationTimerField(
                                  seconds: (set['duration'] as int?) ?? (_exerciseTimerSeconds[timerKey] ?? 0),
                                  isRunning: isTimerRunning,
                                  isDone: done,
                                  onStart: () => _startExerciseTimer(exId, i),
                                  onStop: () => _stopExerciseTimer(exId, i),
                                  onManualEdit: (v) {
                                    setState(() {
                                      _sets[exId]![i]['duration'] = v;
                                      _exerciseTimerSeconds[timerKey] = v;
                                    });
                                    _saveSetsToProvider();
                                  },
                                )
                              : _NumberField(
                                  value: set['reps'],
                                  isDecimal: false,
                                  onChanged: (v) {
                                    setState(() => _sets[exId]![i]['reps'] = v);
                                    _saveSetsToProvider();
                                  },
                                ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _toggleSetDone(exId, i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: done ? AppTheme.successColor : AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: done ? AppTheme.successColor : Colors.white24),
                            ),
                            child: done
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                          ),
                        ),
                      ]),
                    );
                  }),

                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _addSet(exId, ex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add, color: AppTheme.primaryColor, size: 16),
                            SizedBox(width: 4),
                            Text('Serie', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                          ]),
                        ),
                      ),
                    ),
                    if (sets.length > 1) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeSet(exId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.4)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.remove, color: AppTheme.errorColor, size: 16),
                        ),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}

/// A widget that shows a Start/Stop timer for duration-based exercises,
/// with the option to manually edit the recorded seconds.
class _DurationTimerField extends StatelessWidget {
  final int seconds;
  final bool isRunning;
  final bool isDone;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Function(int) onManualEdit;

  const _DurationTimerField({
    required this.seconds,
    required this.isRunning,
    required this.isDone,
    required this.onStart,
    required this.onStop,
    required this.onManualEdit,
  });

  String _fmt(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      // Show recorded duration as editable text
      return GestureDetector(
        onTap: () async {
          final ctrl = TextEditingController(text: seconds.toString());
          final result = await showDialog<int>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Modifica durata (secondi)'),
              content: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(suffixText: 's'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text) ?? seconds),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (result != null) onManualEdit(result);
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('${seconds}s',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.successColor)),
          ),
        ),
      );
    }

    // Interactive timer: show current count and Start/Stop button
    return GestureDetector(
      onTap: isRunning ? onStop : onStart,
      onLongPress: () async {
        // Long press to manually edit
        final ctrl = TextEditingController(text: seconds.toString());
        final result = await showDialog<int>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceColor,
            title: const Text('Modifica durata (secondi)'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(suffixText: 's'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text) ?? seconds),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (result != null) onManualEdit(result);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        decoration: BoxDecoration(
          color: isRunning
              ? AppTheme.primaryColor.withValues(alpha: 0.2)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isRunning ? AppTheme.primaryColor : Colors.white12,
            width: isRunning ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRunning ? Icons.stop : Icons.play_arrow,
              size: 16,
              color: isRunning ? AppTheme.primaryColor : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              _fmt(seconds),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isRunning ? AppTheme.primaryColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  final dynamic value;
  final bool isDecimal;
  final Function(dynamic) onChanged;
  const _NumberField({required this.value, required this.isDecimal, required this.onChanged});
  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _controller = TextEditingController(text: (v == 0 || v == 0.0) ? '' : v.toString());
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
      textInputAction: TextInputAction.done,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.isDecimal ? '0.0' : '0',
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: (v) {
        final parsed = widget.isDecimal ? double.tryParse(v) : int.tryParse(v);
        if (parsed != null) widget.onChanged(parsed);
      },
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
