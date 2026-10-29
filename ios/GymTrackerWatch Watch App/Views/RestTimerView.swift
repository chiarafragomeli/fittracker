import SwiftUI
import WatchKit

struct RestTimerView: View {
    @Environment(WorkoutManager.self) var workoutManager

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Recupero")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(workoutManager.restTimeRemaining ?? 0)s")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .foregroundColor(.blue)
            }
            
            Spacer()

            Button("Salta") {
                workoutManager.skipRestTimer()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal)
    }
}
