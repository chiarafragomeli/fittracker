import SwiftUI

struct WorkoutSummaryView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(ConnectivityManager.self) var connectivityManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let currentDuration = workoutManager.elapsedTime(at: Date())
        let avgBpm = workoutManager.averageHeartRate > 0 ? workoutManager.averageHeartRate : workoutManager.heartRate

        ScrollView {
            VStack(spacing: 16) {
                Text("Riepilogo")
                    .font(.title3.bold())

                VStack(alignment: .leading, spacing: 8) {
                    SummaryRow(title: "Durata", value: formatTime(currentDuration))
                    SummaryRow(title: "Calorie", value: "\(Int(workoutManager.activeCalories)) kcal")
                    SummaryRow(title: "FC Media", value: "\(Int(avgBpm)) bpm")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

                Button("Salva Allenamento") {
                    Task {
                        let endDate = Date()
                        let finalDuration = workoutManager.elapsedTime(at: endDate)
                        let startDate = workoutManager.startDate ?? endDate.addingTimeInterval(-finalDuration)
                        let workoutId = workoutManager.workoutId.isEmpty ? "workout_\(Int(startDate.timeIntervalSince1970 * 1000))" : workoutManager.workoutId
                        let _ = try? await workoutManager.endWorkout()
                        connectivityManager.sendCompletedWorkout(data: [
                            "id": workoutId,
                            "workoutId": workoutId,
                            "routineId": workoutManager.currentRoutine?.id ?? "",
                            "name": workoutManager.currentRoutine?.name ?? "Allenamento Watch",
                            "startTimeMs": Int(startDate.timeIntervalSince1970 * 1000),
                            "endTimeMs": Int(endDate.timeIntervalSince1970 * 1000),
                            "duration": finalDuration,
                            "calories": workoutManager.activeCalories,
                            "sets": workoutManager.completedSets
                        ])
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Scarta Allenamento") {
                    let wId = workoutManager.workoutId
                    workoutManager.discardWorkout()
                    if !wId.isEmpty {
                        connectivityManager.sendWorkoutDiscarded(workoutId: wId)
                    }
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
