import SwiftUI

struct ExercisePageView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Binding var showingSummary: Bool

    @State private var currentReps: Int = 0
    @State private var currentWeight: Double = 0.0

    var body: some View {
        ScrollView {
            if let routine = workoutManager.currentRoutine, !routine.exercises.isEmpty {
                let exercise = routine.exercises[workoutManager.currentExerciseIndex]
                let isExerciseDone = workoutManager.currentSetIndex >= exercise.defaultSets
                let displaySetNumber = min(workoutManager.currentSetIndex + 1, exercise.defaultSets)

                VStack(spacing: 6) {
                    // Navigation header
                    HStack {
                        Button(action: { workoutManager.previousExercise() }) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        .disabled(workoutManager.currentExerciseIndex == 0)

                        Spacer()

                        Text("\(workoutManager.currentExerciseIndex + 1)/\(routine.exercises.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { workoutManager.nextExercise() }) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.plain)
                        .disabled(workoutManager.currentExerciseIndex == routine.exercises.count - 1)
                    }
                    .padding(.horizontal, 4)

                    Text(exercise.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if isExerciseDone {
                        Text("Completato (\(workoutManager.currentSetIndex)/\(exercise.defaultSets) serie) ✓")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("\(exercise.muscleGroup) • Serie \(displaySetNumber)/\(exercise.defaultSets)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if exercise.metricType == "reps" {
                        VStack(spacing: 6) {
                            // Reps row with visible numeric value
                            HStack {
                                Button(action: {
                                    if currentReps > 0 { currentReps -= 1 }
                                }) {
                                    Image(systemName: "minus")
                                }
                                .buttonStyle(.bordered)
                                .frame(width: 36)

                                Spacer()
                                Text("\(currentReps) reps")
                                    .font(.subheadline.bold())
                                    .monospacedDigit()
                                Spacer()

                                Button(action: {
                                    if currentReps < 200 { currentReps += 1 }
                                }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.bordered)
                                .frame(width: 36)
                            }

                            // Weight row with visible numeric value (step 0.25 kg)
                            HStack {
                                Button(action: {
                                    let nextWeight = (round((currentWeight - 0.25) * 4.0) / 4.0)
                                    currentWeight = max(0.0, nextWeight)
                                }) {
                                    Image(systemName: "minus")
                                }
                                .buttonStyle(.bordered)
                                .frame(width: 36)

                                Spacer()
                                Text(formatWeight(currentWeight))
                                    .font(.subheadline.bold())
                                    .monospacedDigit()
                                Spacer()

                                Button(action: {
                                    let nextWeight = (round((currentWeight + 0.25) * 4.0) / 4.0)
                                    currentWeight = min(500.0, nextWeight)
                                }) {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.bordered)
                                .frame(width: 36)
                            }
                        }
                        .padding(.vertical, 2)
                    } else {
                        VStack(spacing: 4) {
                            Text("\(workoutManager.durationTimeRemaining)s")
                                .font(.title3.bold())
                                .monospacedDigit()

                            HStack {
                                if workoutManager.isDurationTimerActive {
                                    Button(action: { workoutManager.pauseDurationTimer() }) {
                                        Image(systemName: "pause.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.yellow)
                                } else {
                                    Button(action: { workoutManager.startDurationTimer() }) {
                                        Image(systemName: "play.fill")
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.green)
                                }

                                Button(action: { workoutManager.resetDurationTimer(to: exercise.defaultDuration) }) {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }

                    if workoutManager.isRestTimerActive {
                        RestTimerView()
                    } else if workoutManager.isRoutineCompleted && isExerciseDone {
                        Button("Termina Allenamento") {
                            showingSummary = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)

                        Button("Aggiungi Serie Extra") {
                            recordCurrentSet(for: exercise)
                        }
                        .buttonStyle(.bordered)
                        .font(.caption2)
                    } else {
                        Button(isExerciseDone ? "Serie Extra" : "Completa Serie") {
                            recordCurrentSet(for: exercise)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(.vertical, 4)
            } else {
                Text("Nessun esercizio")
            }
        }
        .containerBackground(.indigo.gradient, for: .tabView)
        .onAppear { setupForCurrentExercise(resetWeight: true) }
        .onChange(of: workoutManager.currentExerciseIndex) { _, _ in
            setupForCurrentExercise(resetWeight: true)
        }
        .onChange(of: workoutManager.currentSetIndex) { _, _ in
            setupForCurrentExercise(resetWeight: false)
        }
    }

    private func recordCurrentSet(for exercise: WatchExercise) {
        let elapsedDur: Int
        if workoutManager.durationTimeRemaining > 0 && workoutManager.durationTimeRemaining < exercise.defaultDuration {
            elapsedDur = exercise.defaultDuration - workoutManager.durationTimeRemaining
        } else {
            elapsedDur = exercise.defaultDuration
        }
        workoutManager.completeCurrentSet(
            reps: currentReps,
            weight: currentWeight,
            durationSeconds: elapsedDur
        )
    }

    private func setupForCurrentExercise(resetWeight: Bool) {
        guard let routine = workoutManager.currentRoutine,
              workoutManager.currentExerciseIndex < routine.exercises.count else { return }
        let exercise = routine.exercises[workoutManager.currentExerciseIndex]
        if exercise.metricType == "reps" {
            currentReps = exercise.defaultReps
            if resetWeight {
                // Pre-fill weight from last completed set of this exercise if available, otherwise 0
                if let lastSet = workoutManager.completedSets.last(where: { ($0["exerciseId"] as? String) == exercise.id }),
                   let lastWeight = lastSet["weight"] as? Double {
                    currentWeight = lastWeight
                } else {
                    currentWeight = 0.0
                }
            }
        } else {
            workoutManager.resetDurationTimer(to: exercise.defaultDuration)
        }
    }

    private func formatWeight(_ w: Double) -> String {
        let rounded = (round(w * 4.0) / 4.0)
        if rounded.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(format: "%.0f kg", rounded)
        } else if (rounded * 10.0).truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(format: "%.1f kg", rounded)
        } else {
            return String(format: "%.2f kg", rounded)
        }
    }
}
