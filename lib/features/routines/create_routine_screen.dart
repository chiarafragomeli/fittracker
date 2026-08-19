import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../exercises/exercises_provider.dart';
import 'routines_provider.dart';

import '../../core/database/models.dart'; // Needed for Routine class

class CreateRoutineScreen extends ConsumerStatefulWidget {
  final Routine? routine;
  const CreateRoutineScreen({super.key, this.routine});

  @override
  ConsumerState<CreateRoutineScreen> createState() =>
      _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _searchController;
  late final List<String> _selectedExerciseIds;
  String _filterGroup = 'Tutti';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.routine?.name ?? '');
    _searchController = TextEditingController();
    _selectedExerciseIds = List.from(widget.routine?.exerciseIds ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per la scheda')),
      );
      return;
    }

    if (widget.routine != null) {
      ref
          .read(routinesProvider.notifier)
          .updateRoutine(widget.routine!.id, name, _selectedExerciseIds);
    } else {
      ref
          .read(routinesProvider.notifier)
          .addRoutine(name, _selectedExerciseIds);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exercisesProvider);
    final activeExercises = allExercises.where((e) => !e.isDeleted).toList();
    final groups = [
      'Tutti',
      ...{for (var e in activeExercises) e.muscleGroup},
    ];

    // First apply group filter, then apply text search filter
    final filteredByGroup = _filterGroup == 'Tutti'
        ? activeExercises
        : activeExercises.where((e) => e.muscleGroup == _filterGroup).toList();

    final filtered = _searchQuery.isEmpty
        ? filteredByGroup
        : filteredByGroup
              .where(
                (e) =>
                    e.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.routine != null ? 'Modifica Scheda' : 'Nuova Scheda',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Salva',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Name field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nome scheda (es. Giorno 3A)',
                prefixIcon: Icon(Icons.edit, color: AppTheme.primaryColor),
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cerca esercizio...',
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: groups.map((g) {
                final selected = _filterGroup == g;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(g),
                    selected: selected,
                    onSelected: (_) => setState(() => _filterGroup = g),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: AppTheme.surfaceColor,
                    side: BorderSide(
                      color: selected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Selected count
          if (_selectedExerciseIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedExerciseIds.length} esercizi selezionati',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final ex = filtered[index];
                final isSelected = _selectedExerciseIds.contains(ex.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedExerciseIds.remove(ex.id);
                      } else {
                        _selectedExerciseIds.add(ex.id);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.15)
                          : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white30,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
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
                              Text(
                                ex.muscleGroup,
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Text(
                            '${_selectedExerciseIds.indexOf(ex.id) + 1}°',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
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
  }
}
