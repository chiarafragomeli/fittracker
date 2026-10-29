import SwiftUI

struct ControlsPageView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Binding var showingSummary: Bool
    @State private var showEndAlert = false

    var body: some View {
        VStack(spacing: 16) {
            Text(workoutManager.currentRoutine?.name ?? "Allenamento")
                .font(.headline)

            Button(action: {
                if workoutManager.isPaused {
                    workoutManager.resumeWorkout()
                } else {
                    workoutManager.pauseWorkout()
                }
            }) {
                Image(systemName: workoutManager.isPaused ? "play.fill" : "pause.fill")
                    .font(.title2)
            }
            .tint(.yellow)
            .buttonStyle(.borderedProminent)

            Button(action: {
                showEndAlert = true
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
            }
            .tint(.red)
            .buttonStyle(.borderedProminent)
        }
        .containerBackground(.gray.gradient, for: .tabView)
        .alert("Terminare l'allenamento?", isPresented: $showEndAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Termina", role: .destructive) {
                showingSummary = true
            }
        }
    }
}
