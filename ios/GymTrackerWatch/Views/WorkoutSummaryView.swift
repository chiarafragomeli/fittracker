import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(ConnectivityManager.self) var connectivityManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Riepilogo")
                    .font(.title3.bold())

                VStack(alignment: .leading, spacing: 8) {
                    SummaryRow(title: "Durata", value: formatTime(workoutManager.elapsedTime))
                    SummaryRow(title: "Calorie", value: "\(Int(workoutManager.activeCalories)) kcal")
                    SummaryRow(title: "FC Media", value: "\(Int(workoutManager.heartRate)) bpm")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                Button("Salva Allenamento") {
                    Task {
                        let _ = try? await workoutManager.endWorkout()
                        connectivityManager.sendCompletedWorkout(data: [
                            "duration": workoutManager.elapsedTime,
                            "calories": workoutManager.activeCalories
                        ])
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Scarta Allenamento") {
                    workoutManager.discardWorkout()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }
}
