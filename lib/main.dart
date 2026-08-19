import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/theme.dart';
import 'core/database/models.dart';
import 'core/database/exercises_repository.dart';
import 'core/database/routines_repository.dart';
import 'features/routines/routines_screen.dart';
import 'features/routines/routines_provider.dart';
import 'features/exercises/exercises_screen.dart';
import 'features/exercises/exercises_provider.dart';
import 'features/profile/profile_screen.dart';
import 'features/workout/workout_provider.dart';
import 'features/workout/active_workout_screen.dart';
import 'import_csv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error boundaries
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
    return true;
  };
  await Hive.initFlutter();
  Hive.registerAdapter(ExerciseAdapter());
  Hive.registerAdapter(WorkoutSetAdapter());
  Hive.registerAdapter(RoutineAdapter());
  Hive.registerAdapter(WorkoutLogAdapter());

  await Hive.openBox<Exercise>('exercises');
  await Hive.openBox<Routine>('routines');
  await Hive.openBox<WorkoutLog>('workout_logs');

  await initializeDateFormatting('it_IT', null);

  // Preload defaults before importing CSV so they don't get recreated as deleted
  final exBox = Hive.box<Exercise>('exercises');
  if (!exBox.containsKey('ex_1')) {
    ExercisesRepository.preloadDefaults(exBox);
  }
  
  final routineBox = Hive.box<Routine>('routines');
  if (!routineBox.containsKey('r_1a')) {
    RoutinesRepository.preloadDefaults(routineBox);
  }

  // Import old workouts if missing
  try {
    await importWorkoutsFromCsv();
  } catch (e) {
    print("Error importing: $e");
  }

  runApp(const ProviderScope(child: GymTrackerApp()));
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],
  );
});

class GymTrackerApp extends ConsumerWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Gym Tracker',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  final _workoutKey = GlobalKey();

  static const List<Widget> _screens = [
    RoutinesScreen(),
    ExercisesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWorkingOut = ref.watch(
      workoutProvider.select((s) => s.isTracking && s.activeRoutine != null),
    );
    final showMiniBanner = ref.watch(
      workoutProvider.select((s) => s.isTracking && s.isMinimized),
    );

    return Stack(
      children: [
        // Main navigation (always visible underneath)
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showMiniBanner)
                Consumer(
                  builder: (context, ref, _) {
                    final workoutState = ref.watch(workoutProvider);
                    return GestureDetector(
                      onTap: () {
                        ref.read(workoutProvider.notifier).maximizeWorkout();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workoutState.activeRoutine?.name ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _formatDuration(workoutState.elapsedTime),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (workoutState.restTimer != null &&
                                workoutState.restTimer!.inSeconds > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.bedtime_outlined,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(workoutState.restTimer!),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list),
                    label: 'Schede',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center),
                    label: 'Esercizi',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profilo',
                  ),
                ],
              ),
            ],
          ),
        ),
        // Active workout overlay — kept alive with Offstage when minimized
        if (isWorkingOut)
          Consumer(
            builder: (context, ref, _) {
              final workoutState = ref.watch(workoutProvider);
              return Positioned.fill(
                child: Offstage(
                  offstage: workoutState.isMinimized,
                  child: ActiveWorkoutScreen(
                    key: _workoutKey,
                    routine: workoutState.activeRoutine!,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}
