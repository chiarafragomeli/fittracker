import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class DurationTimerField extends StatelessWidget {
  final int seconds;
  final bool isRunning;
  final bool isDone;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Function(int) onManualEdit;

  const DurationTimerField({
    super.key,
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
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annulla'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(ctx, int.tryParse(ctrl.text) ?? seconds),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          ctrl.dispose();
          if (result != null) onManualEdit(result);
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${seconds}s',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.successColor,
              ),
            ),
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, int.tryParse(ctrl.text) ?? seconds),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        ctrl.dispose();
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
