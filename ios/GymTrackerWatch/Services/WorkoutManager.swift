import Foundation
import HealthKit
import Observation
import WatchKit

@Observable
class WorkoutManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    var heartRate: Double = 0
    var activeCalories: Double = 0
    var elapsedTime: TimeInterval = 0
    var isRunning: Bool = false
    var isPaused: Bool = false

    var currentExerciseIndex: Int = 0
    var currentSetIndex: Int = 0
    var restTimeRemaining: Int? = nil
    var isRestTimerActive: Bool = false
    var currentRoutine: WatchRoutine?

    private var healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?

    func requestAuthorization() async throws {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    func startWorkout(routine: WatchRoutine) async throws {
        self.currentRoutine = routine
        let activityType: HKWorkoutActivityType
        switch routine.healthActivityType {
        case "highIntensityIntervalTraining": activityType = .highIntensityIntervalTraining
        case "functionalStrengthTraining": activityType = .functionalStrengthTraining
        default: activityType = .traditionalStrengthTraining
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType
        configuration.locationType = .indoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        builder = session?.associatedWorkoutBuilder()
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

        session?.delegate = self
        builder?.delegate = self

        session?.startActivity(with: Date())
        try await builder?.beginCollection(at: Date())

        DispatchQueue.main.async {
            self.isRunning = true
            self.currentExerciseIndex = 0
            self.currentSetIndex = 0
        }
    }

    func pauseWorkout() {
        session?.pause()
        isPaused = true
    }

    func resumeWorkout() {
        session?.resume()
        isPaused = false
    }

    func completeCurrentSet() {
        guard let routine = currentRoutine, currentExerciseIndex < routine.exercises.count else { return }
        let exercise = routine.exercises[currentExerciseIndex]
        
        currentSetIndex += 1
        
        if currentSetIndex >= exercise.defaultSets {
            // Move to next exercise if possible
            if currentExerciseIndex < routine.exercises.count - 1 {
                currentExerciseIndex += 1
                currentSetIndex = 0
                startRestTimer(seconds: exercise.restSeconds)
            }
        } else {
            // Start rest timer
            startRestTimer(seconds: exercise.restSeconds)
        }
    }
    
    private func startRestTimer(seconds: Int) {
        guard seconds > 0 else { return }
        isRestTimerActive = true
        restTimeRemaining = seconds
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let remaining = self.restTimeRemaining else { return }
                if remaining > 0 {
                    self.restTimeRemaining = remaining - 1
                } else {
                    self.skipRestTimer()
                    WKInterfaceDevice.current().play(.success)
                }
            }
        }
    }

    func skipRestTimer() {
        timer?.invalidate()
        timer = nil
        isRestTimerActive = false
        restTimeRemaining = nil
    }

    func nextExercise() {
        guard let routine = currentRoutine else { return }
        if currentExerciseIndex < routine.exercises.count - 1 {
            currentExerciseIndex += 1
            currentSetIndex = 0
            skipRestTimer()
        }
    }

    func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            currentSetIndex = 0
            skipRestTimer()
        }
    }

    func endWorkout() async throws -> HKWorkout? {
        session?.end()
        try await builder?.endCollection(at: Date())
        let workout = try await builder?.finishWorkout()
        DispatchQueue.main.async {
            self.isRunning = false
            self.timer?.invalidate()
        }
        return workout
    }

    func discardWorkout() {
        session?.end()
        builder?.discardWorkout()
        isRunning = false
        timer?.invalidate()
    }

    // MARK: - HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.isPaused = (toState == .paused)
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Handle error
    }

    // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            if let statistics = workoutBuilder.statistics(for: quantityType) {
                DispatchQueue.main.async {
                    if quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                        self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) ?? 0
                    } else if quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                        self.activeCalories = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                    }
                }
            }
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        DispatchQueue.main.async {
            self.elapsedTime = workoutBuilder.elapsedTime
        }
    }
}
