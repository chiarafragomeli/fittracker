import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class SettingsNotifier extends Notifier<bool> {
  late final Box _box;

  @override
  bool build() {
    _box = Hive.box('settings');
    return _box.get('sync_health_kit', defaultValue: false);
  }

  void toggleSyncHealthKit(bool value) {
    state = value;
    _box.put('sync_health_kit', value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, bool>(() {
  return SettingsNotifier();
});
