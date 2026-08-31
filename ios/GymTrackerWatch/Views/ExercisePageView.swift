import SwiftUI

struct ExercisePageView: View {
    @Environment(WorkoutManager.self) var workoutManager

    var body: some View {
        ZStack {
            if let routine = workoutManager.currentRoutine, routine.exercises.count > 0 {
                let exercise = routine.exercises[workoutManager.currentExerciseIndex]
                
                VStack(spacing: 8) {
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
                    .padding(.horizontal)

                    Text(exercise.name)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text(exercise.muscleGroup)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Serie \(workoutManager.currentSetIndex + 1) di \(exercise.defaultSets)")
                        .font(.subheadline)
                        .padding(.top, 4)

                    if exercise.metricType == "reps" {
                        Text("\(exercise.defaultReps) Ripetizioni")
                            .font(.title3.bold())
                    } else {
                        Text("\(exercise.defaultDuration) Secondi")
                            .font(.title3.bold())
                    }

                    Spacer()

                    Button("Completa Serie") {
                        workoutManager.completeCurrentSet()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.vertical)
            } else {
                Text("Nessun esercizio")
            }
            
            if workoutManager.isRestTimerActive {
                RestTimerView()
                    .background(.black.opacity(0.8))
            }
        }
        .containerBackground(.indigo.gradient, for: .tabView)
    }
}
