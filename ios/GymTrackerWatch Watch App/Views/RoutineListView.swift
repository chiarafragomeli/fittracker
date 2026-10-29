import SwiftUI

struct RoutineListView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(ConnectivityManager.self) var connectivityManager
    @State private var showingWorkout = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                if workoutManager.isRunning, let currentRoutine = workoutManager.currentRoutine {
                    Section {
                        Button {
                            showingWorkout = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("In corso: \(currentRoutine.name)")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                    Text("Tocca per riprendere")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.green.opacity(0.18))
                    }
                }

                Section("Schede Disponibili") {
                    ForEach(connectivityManager.routines) { routine in
                        Button {
                            if workoutManager.isRunning {
                                // If a workout is already running, resume it instead of starting a new one
                                showingWorkout = true
                                return
                            }
                            Task {
                                do {
                                    try await workoutManager.requestAuthorization()
                                    try await workoutManager.startWorkout(routine: routine)
                                    showingWorkout = true
                                    let startMs = Int((workoutManager.startDate ?? Date()).timeIntervalSince1970 * 1000)
                                    connectivityManager.sendWorkoutStarted(
                                        workoutId: workoutManager.workoutId,
                                        routineId: routine.id,
                                        routineName: routine.name,
                                        startTimeMs: startMs
                                    )
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
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
                }
            }
            .navigationTitle("MyGymBro")
            .containerBackground(.blue.gradient, for: .navigation)
            .onAppear {
                connectivityManager.requestSyncFromPhone()
                if workoutManager.isRunning && !showingWorkout {
                    showingWorkout = true
                }
            }
            .fullScreenCover(isPresented: $showingWorkout) {
                ActiveWorkoutView()
            }
            .onChange(of: workoutManager.isRunning) { _, isRunning in
                showingWorkout = isRunning
            }
            .alert("Avviso HealthKit", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}
