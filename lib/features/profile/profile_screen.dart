import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/theme.dart';
import '../../core/database/models.dart';
import 'package:intl/intl.dart';
import '../exercises/exercises_provider.dart';
import 'workout_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo e Statistiche')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<WorkoutLog>('workout_logs').listenable(),
        builder: (context, Box<WorkoutLog> box, _) {
          final logs = box.values.toList();

          // Stats calc
          final now = DateTime.now();
          int daily = 0;
          int weekly = 0;
          int monthly = 0;

          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfMonth = DateTime(now.year, now.month, 1);

          for (final log in logs) {
            if (log.startTime.year == now.year &&
                log.startTime.month == now.month &&
                log.startTime.day == now.day) {
              daily++;
            }
            if (log.startTime.isAfter(
              startOfWeek.subtract(const Duration(days: 1)),
            )) {
              weekly++;
            }
            if (log.startTime.isAfter(
              startOfMonth.subtract(const Duration(days: 1)),
            )) {
              monthly++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Le tue statistiche',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Oggi',
                        value: '$daily',
                        subtitle: 'Allenamenti',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WorkoutHistoryScreen(filterMode: 'today'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Questa Settimana',
                        value: '$weekly',
                        subtitle: 'Allenamenti',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WorkoutHistoryScreen(filterMode: 'week'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Questo Mese',
                        value: '$monthly',
                        subtitle: 'Allenamenti',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WorkoutHistoryScreen(filterMode: 'month'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Calendar header
                const Text(
                  'Calendario Allenamenti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                          );
                        });
                      },
                    ),
                    Text(
                      DateFormat(
                        'MMMM yyyy',
                        'it_IT',
                      ).format(_focusedMonth).toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCalendar(logs),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWorkoutDetails(
    BuildContext context,
    DateTime date,
    List<WorkoutLog> logs,
  ) {
    final dayLogs = logs
        .where(
          (l) =>
              l.startTime.year == date.year &&
              l.startTime.month == date.month &&
              l.startTime.day == date.day,
        )
        .toList();
    if (dayLogs.isEmpty) return;

    final exercises = ref.read(exercisesProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Allenamenti - ${DateFormat('d MMMM yyyy', 'it_IT').format(date)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: dayLogs.length,
                      itemBuilder: (context, index) {
                        final log = dayLogs[index];
                        final duration = log.endTime != null
                            ? log.endTime!.difference(log.startTime)
                            : null;

                        // Group sets by exercise
                        final Map<String, List<WorkoutSet>> setsByExercise = {};
                        for (final s in log.sets) {
                          setsByExercise
                              .putIfAbsent(s.exerciseId, () => [])
                              .add(s);
                        }

                        return Card(
                          color: AppTheme.backgroundColor,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.name.isNotEmpty
                                      ? log.name
                                      : 'Allenamento ${DateFormat('HH:mm').format(log.startTime)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('HH:mm').format(log.startTime)} - ${log.endTime != null ? DateFormat('HH:mm').format(log.endTime!) : 'In corso'}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                    if (duration != null) ...[
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.timer,
                                        size: 16,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${duration.inMinutes} min',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...setsByExercise.entries.map((entry) {
                                  final exId = entry.key;
                                  final exSets = entry.value;
                                  final exercise = exercises.firstWhere(
                                    (e) => e.id == exId,
                                    orElse: () => Exercise(
                                      id: exId,
                                      name: 'Esercizio sconosciuto',
                                      muscleGroup: 'Altro',
                                      metricType: MetricType.reps,
                                    ),
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ...exSets.asMap().entries.map((
                                          setEntry,
                                        ) {
                                          final setIdx = setEntry.key + 1;
                                          final s = setEntry.value;

                                          String detail = '';
                                          if (exercise.metricType ==
                                              MetricType.reps) {
                                            detail =
                                                '${s.reps} reps' +
                                                (s.weight > 0
                                                    ? ' @ ${s.weight} kg'
                                                    : '');
                                          } else {
                                            detail =
                                                '${s.durationSeconds} s' +
                                                (s.weight > 0
                                                    ? ' @ ${s.weight} kg'
                                                    : '');
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8,
                                              bottom: 2,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Set $setIdx: ',
                                                  style: const TextStyle(
                                                    color: AppTheme
                                                        .textSecondaryColor,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  detail,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (s.isCompleted)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 4,
                                                    ),
                                                    child: Icon(
                                                      Icons.check_circle,
                                                      size: 12,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendar(List<WorkoutLog> logs) {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    // Create a set of days that have workouts
    final workoutDays = <int>{};
    for (final log in logs) {
      if (log.startTime.year == _focusedMonth.year &&
          log.startTime.month == _focusedMonth.month) {
        workoutDays.add(log.startTime.day);
      }
    }

    final weekdays = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 weeks
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              final day = dayOffset + 1;

              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink(); // Empty slot
              }

              final hasWorkout = workoutDays.contains(day);
              final isToday =
                  DateTime.now().year == _focusedMonth.year &&
                  DateTime.now().month == _focusedMonth.month &&
                  DateTime.now().day == day;

              return GestureDetector(
                onTap: hasWorkout
                    ? () {
                        final date = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month,
                          day,
                        );
                        _showWorkoutDetails(context, date, logs);
                      }
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: hasWorkout
                        ? AppTheme.primaryColor
                        : (isToday
                              ? AppTheme.backgroundColor
                              : Colors.transparent),
                    shape: BoxShape.circle,
                    border: isToday && !hasWorkout
                        ? Border.all(color: AppTheme.primaryColor, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: hasWorkout
                            ? Colors.white
                            : AppTheme.textPrimaryColor,
                        fontWeight: (hasWorkout || isToday)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
