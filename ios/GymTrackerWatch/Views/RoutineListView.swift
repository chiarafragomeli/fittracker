import SwiftUI

struct RoutineListView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(ConnectivityManager.self) var connectivityManager
    @State private var showingWorkout = false

    var body: some View {
        NavigationStack {
            List(connectivityManager.routines) { routine in
                Button {
                    Task {
                        do {
                            try await workoutManager.requestAuthorization()
                            try await workoutManager.startWorkout(routine: routine)
                            showingWorkout = true
                        } catch {
                            print("Error starting workout: \(error)")
                        }
                    }
                } label: {
                    VStack(alignment: .leading) {
                        Text(routine.name)
                            .font(.headline)
                        Text("\(routine.exercises.count) esercizi")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("MyGymBro")
            .containerBackground(.blue.gradient, for: .navigation)
            .fullScreenCover(isPresented: $showingWorkout) {
                ActiveWorkoutView()
            }
        }
    }
}
