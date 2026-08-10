import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exercises_provider.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Libreria Esercizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add custom exercise
            },
          ),
        ],
      ),
      body: exercises.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: exercises.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ex = exercises[index];
                return ListTile(
                  title: Text(ex.name),
                  subtitle: Text(ex.muscleGroup),
                  trailing: ex.isCustom ? const Icon(Icons.star, size: 16) : null,
                );
              },
            ),
    );
  }
}
