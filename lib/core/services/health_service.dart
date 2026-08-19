import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

class HealthService {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    // We only need to write workouts
    final types = [HealthDataType.WORKOUT];
    final permissions = [HealthDataAccess.WRITE];
    
    try {
      bool authorized = await _health.requestAuthorization(types, permissions: permissions);
      return authorized;
    } catch (e) {
      debugPrint('Error requesting HealthKit authorization: $e');
      return false;
    }
  }

  Future<bool> saveWorkout({
    required DateTime start,
    required DateTime end,
    required String activityTypeStr,
    int? totalEnergyBurned,
    int? totalDistance,
  }) async {
    HealthWorkoutActivityType? activityType = _mapActivityType(activityTypeStr);
    
    if (activityType == null) {
      debugPrint('HealthService: Activity type is none or invalid ($activityTypeStr). Skipping sync.');
      return false;
    }

    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      debugPrint('HealthService: Missing HealthKit permissions.');
      return false;
    }

    try {
      return await _health.writeWorkoutData(
        activityType: activityType,
        title: 'Gym Tracker Workout',
        start: start,
        end: end,
        totalEnergyBurned: totalEnergyBurned,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
        totalDistance: totalDistance,
        totalDistanceUnit: HealthDataUnit.METER,
      );
    } catch (e) {
      debugPrint('Error writing workout to HealthKit: $e');
      return false;
    }
  }

  HealthWorkoutActivityType? _mapActivityType(String type) {
    switch (type) {
      case 'traditionalStrengthTraining':
        return HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING;
      case 'highIntensityIntervalTraining':
        return HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING;
      case 'functionalStrengthTraining':
        return HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING;
      case 'none':
      default:
        return null;
    }
  }
}
