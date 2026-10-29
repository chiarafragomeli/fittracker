import Foundation
import HealthKit
import Observation
import WatchKit

@Observable
class WorkoutManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    var heartRate: Double = 0
    var averageHeartRate: Double = 0
    var activeCalories: Double = 0
    var elapsedTime: TimeInterval = 0
    var isRunning: Bool = false
    var isPaused: Bool = false
    var isRoutineCompleted: Bool = false

    var currentExerciseIndex: Int = 0
    var currentSetIndex: Int = 0
    var restTimeRemaining: Int? = nil
    var isRestTimerActive: Bool = false
    var currentRoutine: WatchRoutine?
    var workoutId: String = ""
    var startDate: Date?
    var completedSets: [[String: Any]] = []
    weak var connectivityManager: ConnectivityManager?

    private var healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timer: Timer?
    private var restEndDate: Date?
    
    // Duration Timer properties
    var durationTimeRemaining: Int = 0
    var isDurationTimerActive: Bool = false
    private var durationTimer: Timer?
    private var durationEndDate: Date?

    func elapsedTime(at date: Date = Date()) -> TimeInterval {
        return builder?.elapsedTime(at: date) ?? elapsedTime
    }

    func requestAuthorization() async throws {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    func completedSetsCount(for exerciseId: String) -> Int {
        return completedSets.filter { ($0["exerciseId"] as? String) == exerciseId }.count
    }

    func startWorkout(routine: WatchRoutine, customId: String? = nil) async throws {
        self.currentRoutine = routine
        self.workoutId = customId ?? "workout_\(Int(Date().timeIntervalSince1970 * 1000))"
        self.startDate = Date()
        self.completedSets = []
        self.skipRestTimer()
        self.pauseDurationTimer()
        DispatchQueue.main.async {
            self.heartRate = 0
            self.averageHeartRate = 0
            self.activeCalories = 0
            self.elapsedTime = 0
            self.isPaused = false
            self.isRoutineCompleted = false
            self.isRunning = true
            self.currentExerciseIndex = 0
            self.currentSetIndex = 0
        }
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
    }

    func pauseWorkout() {
        session?.pause()
        pauseDurationTimer()
        isPaused = true
    }

    func resumeWorkout() {
        session?.resume()
        isPaused = false
    }

    func completeCurrentSet(reps: Int = 0, weight: Double = 0.0, durationSeconds: Int = 0) {
        guard let routine = currentRoutine, currentExerciseIndex < routine.exercises.count else { return }
        let exercise = routine.exercises[currentExerciseIndex]
        let roundedWeight = (round(weight * 4.0) / 4.0)
        
        let setEntry: [String: Any] = [
            "exerciseId": exercise.id,
            "weight": roundedWeight,
            "reps": exercise.metricType == "reps" ? reps : 0,
            "durationSeconds": exercise.metricType == "duration" ? durationSeconds : 0,
            "isCompleted": true
        ]
        completedSets.append(setEntry)
        pauseDurationTimer()
        
        let doneForCurrent = completedSetsCount(for: exercise.id)
        currentSetIndex = doneForCurrent
        
        let setIndexDone = doneForCurrent - 1
        let nextExName = (currentExerciseIndex < routine.exercises.count) ? routine.exercises[currentExerciseIndex].name : exercise.name
        let nextSetNum = currentSetIndex + 1
        let totalSets = (currentExerciseIndex < routine.exercises.count) ? routine.exercises[currentExerciseIndex].defaultSets : exercise.defaultSets

        connectivityManager?.sendSetCompleted(
            workoutId: workoutId,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            setIndex: setIndexDone,
            weight: roundedWeight,
            reps: exercise.metricType == "reps" ? reps : 0,
            durationSeconds: exercise.metricType == "duration" ? durationSeconds : 0,
            restSeconds: exercise.restSeconds,
            nextExerciseName: nextExName,
            nextSetInfo: "Serie \(nextSetNum)/\(totalSets)"
        )
        
        if currentSetIndex >= exercise.defaultSets {
            // Move to next exercise if possible
            if currentExerciseIndex < routine.exercises.count - 1 {
                currentExerciseIndex += 1
                let nextEx = routine.exercises[currentExerciseIndex]
                currentSetIndex = completedSetsCount(for: nextEx.id)
                startRestTimer(seconds: exercise.restSeconds)
            } else {
                // Last set of the last exercise completed
                skipRestTimer()
                isRoutineCompleted = true
                WKInterfaceDevice.current().play(.success)
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
        restEndDate = Date().addingTimeInterval(TimeInterval(seconds))
        timer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let endDate = self.restEndDate else { return }
                let remaining = Int(ceil(endDate.timeIntervalSinceNow))
                if remaining > 0 {
                    if self.restTimeRemaining != remaining {
                        self.restTimeRemaining = remaining
                    }
                } else {
                    self.skipRestTimer()
                    WKInterfaceDevice.current().play(.success)
                }
            }
        }
        newTimer.tolerance = 0.2
        timer = newTimer
    }

    func skipRestTimer() {
        timer?.invalidate()
        timer = nil
        restEndDate = nil
        isRestTimerActive = false
        restTimeRemaining = nil
    }

    func completeSetFromPhone(
        exerciseId: String,
        setIndex: Int,
        weight: Double,
        reps: Int,
        durationSeconds: Int,
        restSeconds: Int
    ) {
        guard let routine = currentRoutine else { return }
        let alreadyDone = completedSets.contains {
            ($0["exerciseId"] as? String) == exerciseId &&
            ($0["setIndex"] as? Int) == setIndex
        }
        if alreadyDone { return }

        let roundedWeight = (round(weight * 4.0) / 4.0)
        let setEntry: [String: Any] = [
            "exerciseId": exerciseId,
            "setIndex": setIndex,
            "weight": roundedWeight,
            "reps": reps,
            "durationSeconds": durationSeconds,
            "isCompleted": true
        ]
        completedSets.append(setEntry)

        if let exIdx = routine.exercises.firstIndex(where: { $0.id == exerciseId }) {
            let exercise = routine.exercises[exIdx]
            let doneForThis = completedSetsCount(for: exercise.id)
            if exIdx == currentExerciseIndex {
                currentSetIndex = doneForThis
                if currentSetIndex >= exercise.defaultSets {
                    if currentExerciseIndex < routine.exercises.count - 1 {
                        currentExerciseIndex += 1
                        let nextEx = routine.exercises[currentExerciseIndex]
                        currentSetIndex = completedSetsCount(for: nextEx.id)
                    } else {
                        isRoutineCompleted = true
                    }
                }
            }
            if restSeconds > 0 {
                startRestTimer(seconds: restSeconds)
            }
        }
    }

    // MARK: - Duration Timer Logic
    func startDurationTimer() {
        guard durationTimeRemaining > 0 else { return }
        isDurationTimerActive = true
        durationEndDate = Date().addingTimeInterval(TimeInterval(durationTimeRemaining))
        durationTimer?.invalidate()
        let newTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let endDate = self.durationEndDate else { return }
                let remaining = Int(ceil(endDate.timeIntervalSinceNow))
                if remaining > 0 {
                    if self.durationTimeRemaining != remaining {
                        self.durationTimeRemaining = remaining
                    }
                } else {
                    self.durationTimeRemaining = 0
                    self.pauseDurationTimer()
                    WKInterfaceDevice.current().play(.success)
                }
            }
        }
        newTimer.tolerance = 0.2
        durationTimer = newTimer
    }

    func pauseDurationTimer() {
        if let endDate = durationEndDate {
            durationTimeRemaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        }
        durationTimer?.invalidate()
        durationTimer = nil
        durationEndDate = nil
        isDurationTimerActive = false
    }

    func resetDurationTimer(to duration: Int) {
        pauseDurationTimer()
        durationTimeRemaining = duration
    }

    func nextExercise() {
        guard let routine = currentRoutine else { return }
        if currentExerciseIndex < routine.exercises.count - 1 {
            pauseDurationTimer()
            currentExerciseIndex += 1
            let ex = routine.exercises[currentExerciseIndex]
            currentSetIndex = completedSetsCount(for: ex.id)
        }
    }

    func previousExercise() {
        guard let routine = currentRoutine else { return }
        if currentExerciseIndex > 0 {
            pauseDurationTimer()
            currentExerciseIndex -= 1
            let ex = routine.exercises[currentExerciseIndex]
            currentSetIndex = completedSetsCount(for: ex.id)
        }
    }

    func endWorkout() async throws -> HKWorkout? {
        session?.end()
        try await builder?.endCollection(at: Date())
        let workout = try await builder?.finishWorkout()
        DispatchQueue.main.async {
            self.elapsedTime = workout?.duration ?? self.elapsedTime
            self.isRunning = false
            self.skipRestTimer()
            self.pauseDurationTimer()
        }
        return workout
    }

    func discardWorkout() {
        session?.end()
        builder?.discardWorkout()
        isRunning = false
        skipRestTimer()
        pauseDurationTimer()
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
                        let bpmUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                        self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: bpmUnit) ?? 0
                        self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: bpmUnit) ?? self.heartRate
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
