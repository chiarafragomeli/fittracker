import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import 'routines_provider.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le Tue Schede'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create routine screen
            },
          ),
        ],
      ),
      body: routines.isEmpty
          ? const Center(
              child: Text(
                'Nessuna scheda creata.\nPremi + per iniziare.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      routine.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      '${routine.exerciseIds.length} Esercizi',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor, size: 40,),
                    onTap: () {
                      // TODO: View routine details or start workout
                    },
                  ),
                );
              },
            ),
    );
  }
}
