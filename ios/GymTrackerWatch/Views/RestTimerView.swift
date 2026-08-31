import SwiftUI
import WatchKit

struct RestTimerView: View {
    @Environment(WorkoutManager.self) var workoutManager

    var body: some View {
        VStack {
            Text("Recupero")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.3)
                    .foregroundColor(.blue)
                
                Text("\(workoutManager.restTimeRemaining ?? 0)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
            }
            .padding()

            Button("Salta Timer") {
                workoutManager.skipRestTimer()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
}
