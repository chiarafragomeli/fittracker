import SwiftUI

struct MetricsPageView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        TimelineView(
            .periodic(
                from: .now,
                by: (isLuminanceReduced || workoutManager.isPaused) ? 15.0 : 1.0
            )
        ) { context in
            let currentElapsed = workoutManager.elapsedTime(at: context.date)
            VStack(alignment: .leading, spacing: 12) {
                Text(formatTime(currentElapsed, hideSeconds: isLuminanceReduced))
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .foregroundColor(.yellow)

                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("\(Int(workoutManager.heartRate)) BPM")
                        .font(.title3)
                }

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.pink)
                    Text("\(Int(workoutManager.activeCalories)) kcal")
                        .font(.title3)
                }
            }
            .padding()
        }
        .containerBackground(.red.gradient, for: .tabView)
    }

    private func formatTime(_ time: TimeInterval, hideSeconds: Bool = false) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        if hideSeconds {
            return String(format: "%02d:--", minutes)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
