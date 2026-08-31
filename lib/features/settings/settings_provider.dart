import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/services/health_service.dart';

class SettingsNotifier extends Notifier<bool> {
  late final Box _box;

  @override
  bool build() {
    _box = Hive.box('settings');
    return _box.get('sync_health_kit', defaultValue: false);
  }

  void toggleSyncHealthKit(bool value) async {
    if (value) {
      final authorized = await HealthService().requestPermissions();
      if (!authorized) {
        // Se l'utente nega o c'è un errore, riportiamo a false
        state = false;
        _box.put('sync_health_kit', false);
        return;
      }
    }
    state = value;
    _box.put('sync_health_kit', value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, bool>(() {
  return SettingsNotifier();
});
