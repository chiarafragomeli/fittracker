import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/database/models.dart';
import '../exercises/exercises_provider.dart';
import '../workout/workout_provider.dart';
import '../../core/watch_connector.dart';
import '../../core/database/repositories_provider.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'components/duration_timer_field.dart';
import 'components/number_field.dart';

import 'components/rest_timer_overlay.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final Routine routine;
  const ActiveWorkoutScreen({super.key, required this.routine});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late Map<String, List<Map<String, dynamic>>> _sets;
  OverlayEntry? _restDoneOverlay;

  // Per-set exercise timer tracking: key = "exId_setIndex"
  final Map<String, Timer> _exerciseTimers = {};
  final Map<String, int> _exerciseTimerSeconds = {};
  final Map<String, bool> _exerciseTimerRunning = {};

  // Cached previous workout history per exercise to avoid DB scans/sorting on rebuilds
  final Map<String, Map<String, dynamic>?> _historyCache = {};

  @override
  void initState() {
    super.initState();
    final allExercises = ref.read(exercisesProvider);
    final exerciseMap = {for (var e in allExercises) e.id: e};
    _precomputeExerciseHistories(exerciseMap);

    final stateSets = ref.read(workoutProvider).activeSets;
    if (stateSets != null && stateSets.isNotEmpty) {
      _sets = Map<String, List<Map<String, dynamic>>>.from(
        stateSets.map(
          (k, v) => MapEntry(
            k,
            List<Map<String, dynamic>>.from(
              v.map((set) => Map<String, dynamic>.from(set)),
            ),
          ),
        ),
      );
    } else {
      _sets = {};
      for (final exId in widget.routine.exerciseIds) {
        final exercise = exerciseMap[exId];
        // Skip deleted or missing exercises
        if (exercise == null || exercise.isDeleted) continue;
        
        final cfg =
            widget.routine.exerciseConfigs[exId] ??
            ExerciseConfig(exerciseId: exId);
        final isDuration = exercise.metricType == MetricType.duration;
        _sets[exId] = List.generate(
          cfg.defaultSets,
          (_) => {
            'weight': 0.0,
            'done': false,
            if (isDuration)
              'duration': cfg.defaultDuration
            else
              'reps': cfg.defaultReps,
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
    _restDoneOverlay = null;
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
    _restDoneOverlay = RestTimerOverlay.buildEntry(context);
    Overlay.of(context).insert(_restDoneOverlay!);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _restDoneOverlay?.remove();
        _restDoneOverlay = null;
      }
    });
  }

  void _addSet(String exId, Exercise ex) {
    setState(() {
      final cfg =
          widget.routine.exerciseConfigs[exId] ??
          ExerciseConfig(exerciseId: exId);
      final isDuration = ex.metricType == MetricType.duration;
      _sets[exId]!.add({
        'weight': 0.0,
        'done': false,
        if (isDuration)
          'duration': cfg.defaultDuration
        else
          'reps': cfg.defaultReps,
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
      final cfg =
          widget.routine.exerciseConfigs[exId] ??
          ExerciseConfig(exerciseId: exId);
      ref
          .read(workoutProvider.notifier)
          .startRestTimer(Duration(seconds: cfg.restSeconds));

      final workoutId = ref.read(workoutProvider).currentWorkout?.id ?? '';
      final setMap = _sets[exId]![i];
      final weight = (setMap['weight'] as num?)?.toDouble() ?? 0.0;
      final reps = (setMap['reps'] as num?)?.toInt() ?? 0;
      final dur = (setMap['duration'] as num?)?.toInt() ?? 0;
      ref.read(watchConnectorProvider).syncSetToWatch(
        workoutId: workoutId,
        exerciseId: exId,
        setIndex: i,
        weight: weight,
        reps: reps,
        durationSeconds: dur,
        restSeconds: cfg.restSeconds,
      );

      final ex = ref.read(exercisesRepositoryProvider).getExercise(exId);
      ref.read(watchConnectorProvider).updateLiveActivity(
        exerciseName: ex?.name ?? '',
        setInfo: 'Serie ${i + 1}/${_sets[exId]!.length}',
      );
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
          _exerciseTimerSeconds[timerKey] =
              (_exerciseTimerSeconds[timerKey] ?? 0) + 1;
          _sets[exId]![setIndex]['duration'] = _exerciseTimerSeconds[timerKey];
        });
      }
    });
  }

  void _stopExerciseTimer(String exId, int setIndex) {
    final timerKey = '${exId}_$setIndex';
    _exerciseTimers[timerKey]?.cancel();
    _exerciseTimerRunning[timerKey] = false;
    setState(() {});
    _saveSetsToProvider();
  }

  Future<void> _handleFinish() async {
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Termina allenamento'),
        content: const Text(
          'Vuoi salvare i progressi o abbandonare senza salvare?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Abbandona',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Salva',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (save == null || !mounted) return;

    // Cancel all exercise timers and sync final state before finishing
    for (final t in _exerciseTimers.values) {
      t.cancel();
    }
    _saveSetsToProvider();

    if (save) {
      ref.read(workoutProvider.notifier).finishWorkout();
    } else {
      ref.read(workoutProvider.notifier).discardWorkout();
    }
  }

  static const Map<String, List<String>> _csvExerciseAliases = {
    'ex_3': ['Ponte Glutei'],
    'ex_4': ['Plank'],
    'ex_5': ['Cable Crunch', 'Crunch (Con Peso Aggiunto)', 'Crunch (Macchina)'],
    'ex_7': ['Hip Thrust (macchina)', 'Hip Thrust (Machine)'],
    'ex_8': ['Stacco Rumeno a Gamba Singola (Manubrio)'],
    'ex_9': ['Stacco da Terra Rumeno (Bilanciere)'],
    'ex_10': ['Affondo Bulgaro (Manubrio)', 'Affondo Bulgaro'],
    'ex_11': ['Estensioni Glutei al Cavo'],
    'ex_12': ['Leg Curl Seduto (Macchina)'],
    'ex_13': ['Step Up'],
    'ex_14': ['Estensioni Glutei al Cavo'],
    'ex_15': ['Calf Raise in Piedi a Una Gamba', 'Calf Raise Gamba Singola in Piedi '],
    'ex_16': ['Rematore al Cavo da Seduto'],
    'ex_17': ['Rematore al Cavo da Seduto - Presa Larga'],
    'ex_18': ['Lat Pulldown (Cavo)', 'Lat Pulldown (Macchina)'],
    'ex_19': ['Lat Pulldown (Cavo)'],
    'ex_20': ['Rematore Manubrio'],
    'ex_21': ['Estensione Dorso (Ipertensione con Peso)', 'Back Extension (Macchina)'],
    'ex_22': ['Panca Inclinata (Manubrio)', 'Lento in Avanti (Manubrio)'],
    'ex_23': ['Alzate Laterali (Manubrio)', 'Aperture Laterali (Manubrio)'],
    'ex_24': ['Lento in Avanti in Piedi (Bilanciere)'],
    'ex_25': ['Curl Bicipiti con EZ Bar'],
    'ex_26': ['Curl Bicipiti (Manubrio)'],
    'ex_27': ['Pushdown Tricipiti con Corda', 'Pushdown Tricipiti'],
    'ex_28': ['Estensione Tricipiti (Manubrio)', 'Estensione Tricipiti Braccio Singolo (Manubrio)'],
    'ex_29': ['Pushdown Tricipiti'],
    'ex_30': ['Stacco Rumeno a Gamba Singola (Manubrio)'],
    'ex_31': ['Affondi (Manubrio)'],
    'ex_32': ['Estensione Tricipiti (Bilanciere)'],
    'ex_33': ['Estensioni Glutei al Cavo'],
    'ex_34': ['Trazione'],
    'ex_35': ['Rematore al Cavo a Braccio Singolo'],
    'ex_36': ['Lento in Avanti Seduto (Macchina)'],
    'ex_37': ['Alzate Laterali (Manubrio)'],
    'ex_38': ['Curl Sopra la Testa (Cavo)'],
    'ex_39': ['Leg Raise Appeso'],
    'ex_40': ['Ponte Glutei Parziale (Bilanciere)'],
    'ex_41': ['Stacco da Terra Rumeno (Bilanciere)'],
    'ex_42': ['Rematore al Cavo da Seduto'],
    'ex_43': ['Plank'],
    'ex_44': ['Lento in Avanti (Manubrio)'],
    'ex_45': ['Crunch (Con Peso Aggiunto)', 'Cable Crunch'],
    'ex_46': ['Estensione Dorso (Ipertensione con Peso)'],
  };

  void _precomputeExerciseHistories(Map<String, Exercise> exerciseMap) {
    if (!Hive.isBoxOpen('workout_logs')) return;
    final box = Hive.box<WorkoutLog>('workout_logs');
    final logs = box.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    final Map<String, List<String>> nameToIds = {};
    if (Hive.isBoxOpen('exercises')) {
      final exBox = Hive.box<Exercise>('exercises');
      for (final ex in exBox.values) {
        nameToIds.putIfAbsent(ex.name, () => []).add(ex.id);
      }
    }

    for (final exId in widget.routine.exerciseIds) {
      final ex = exerciseMap[exId];
      if (ex == null) continue;
      final isDuration = ex.metricType == MetricType.duration;

      final matchingIds = <String>{exId};
      final aliases = _csvExerciseAliases[exId];
      if (aliases != null) {
        for (final alias in aliases) {
          final ids = nameToIds[alias];
          if (ids != null) matchingIds.addAll(ids);
        }
      }

      Map<String, dynamic>? foundHistory;
      for (final log in logs) {
        final sets = log.sets
            .where((s) => matchingIds.contains(s.exerciseId) && s.isCompleted)
            .toList();
        if (sets.isNotEmpty) {
          double maxWeight = 0;
          int maxMetric = 0;
          for (final s in sets) {
            if (s.weight > maxWeight) maxWeight = s.weight;
            final metric = isDuration ? s.durationSeconds : s.reps;
            if (metric > maxMetric) maxMetric = metric;
          }
          foundHistory = {
            'date': log.startTime,
            'maxWeight': maxWeight,
            'maxMetric': maxMetric,
            'totalSets': sets.length,
          };
          break;
        }
      }
      _historyCache[exId] = foundHistory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkoutName = ref.watch(
      workoutProvider.select((s) => s.currentWorkout?.name),
    );

    // Show overlay when rest timer finishes
    ref.listen<bool>(
      workoutProvider.select((s) => s.restTimerJustFinished),
      (prev, next) {
        if (next && !(prev ?? false)) {
          _showRestDoneOverlay();
          ref.read(workoutProvider.notifier).acknowledgeRestFinished();
        }
      },
    );

    // Update local _sets when activeSets is updated externally (e.g. from Apple Watch)
    ref.listen<Map<String, List<Map<String, dynamic>>>?>(
      workoutProvider.select((s) => s.activeSets),
      (prev, next) {
        if (next != null) {
          setState(() {
            _sets = Map<String, List<Map<String, dynamic>>>.from(
              next.map(
                (k, v) => MapEntry(
                  k,
                  List<Map<String, dynamic>>.from(
                    v.map((set) => Map<String, dynamic>.from(set)),
                  ),
                ),
              ),
            );
          });
        }
      },
    );

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
            onPressed: () {
              _saveSetsToProvider();
              ref.read(workoutProvider.notifier).minimizeWorkout();
            },
          ),
          title: GestureDetector(
            onTap: () async {
              final currentName = currentWorkoutName ?? widget.routine.name;
              final ctrl = TextEditingController(text: currentName);
              final newName = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.surfaceColor,
                  title: const Text('Rinomina allenamento'),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Nome allenamento',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annulla'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                      child: const Text('Salva'),
                    ),
                  ],
                ),
              );
              ctrl.dispose();
              if (!mounted) return;
              if (newName != null &&
                  newName.isNotEmpty &&
                  newName != currentName) {
                ref.read(workoutProvider.notifier).updateWorkoutName(newName);
              }
            },
            child: Container(
              color: Colors.transparent, // to make the whole area tappable
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          currentWorkoutName ?? widget.routine.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Consumer(
                        builder: (context, ref, _) {
                          final elapsedTime = ref.watch(
                            workoutProvider.select((s) => s.elapsedTime),
                          );
                          return Text(
                            _formatDuration(elapsedTime),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final restTimer = ref.watch(
                  workoutProvider.select((s) => s.restTimer),
                );
                if (restTimer == null || restTimer.inSeconds <= 0) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () =>
                      ref.read(workoutProvider.notifier).cancelRestTimer(),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bedtime_outlined,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(restTimer),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.close,
                          size: 12,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: _handleFinish,
              child: const Text(
                'Fine',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
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
            final hasNotes =
                (ex.notes.isNotEmpty) ||
                (cfg?.routineNotes.isNotEmpty ?? false);
            final isDuration = ex.metricType == MetricType.duration;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${exIndex + 1}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    ex.muscleGroup,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isDuration) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '⏱ Tempo',
                                        style: TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Notes
                    if (hasNotes) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                [
                                  if (cfg?.routineNotes.isNotEmpty ?? false)
                                    cfg!.routineNotes,
                                  if (ex.notes.isNotEmpty) ex.notes,
                                ].join('\n'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Previous history (cached in initState)
                    Builder(
                      builder: (context) {
                        final history = _historyCache[exId];
                        if (history == null) return const SizedBox.shrink();

                        final dateStr = DateFormat(
                          'dd MMM yyyy',
                          'it_IT',
                        ).format(history['date'] as DateTime);
                        final metricStr = isDuration
                            ? '${history['maxMetric']}s'
                            : '${history['maxMetric']} reps';
                        final weightStr = history['maxWeight'] > 0
                            ? ' @ ${history['maxWeight']}kg'
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ultima volta ($dateStr): ${history['totalSets']} set | Max: $metricStr$weightStr',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 36,
                              child: Text(
                                'Set',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Kg',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                isDuration ? 'Tempo' : 'Reps',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 44,
                              child: Text(
                                '✓',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Set rows
                    ...sets.asMap().entries.map((entry) {
                      final i = entry.key;
                      final set = entry.value;
                      final done = set['done'] as bool;
                      final timerKey = '${exId}_$i';
                      final isTimerRunning =
                          _exerciseTimerRunning[timerKey] == true;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.successColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: done
                                      ? AppTheme.successColor
                                      : Colors.white70,
                                ),
                              ),
                            ),
                            // Weight field (same for both types)
                            Expanded(
                              child: NumberField(
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
                                  ? DurationTimerField(
                                      seconds:
                                          (set['duration'] as int?) ??
                                          (_exerciseTimerSeconds[timerKey] ??
                                              0),
                                      isRunning: isTimerRunning,
                                      isDone: done,
                                      onStart: () =>
                                          _startExerciseTimer(exId, i),
                                      onStop: () => _stopExerciseTimer(exId, i),
                                      onManualEdit: (v) {
                                        setState(() {
                                          _sets[exId]![i]['duration'] = v;
                                          _exerciseTimerSeconds[timerKey] = v;
                                        });
                                        _saveSetsToProvider();
                                      },
                                    )
                                  : NumberField(
                                      value: set['reps'],
                                      isDecimal: false,
                                      onChanged: (v) {
                                        setState(
                                          () => _sets[exId]![i]['reps'] = v,
                                        );
                                        _saveSetsToProvider();
                                      },
                                    ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _toggleSetDone(exId, i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: done
                                      ? AppTheme.successColor
                                      : AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: done
                                        ? AppTheme.successColor
                                        : Colors.white24,
                                  ),
                                ),
                                child: done
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _addSet(exId, ex),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: AppTheme.primaryColor,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Serie',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (sets.length > 1) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _removeSet(exId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.errorColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: AppTheme.errorColor,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

