import SwiftUI

@main
struct GymTrackerWatchApp: App {
    @State private var workoutManager = WorkoutManager()
    @State private var connectivityManager = ConnectivityManager()

    var body: some Scene {
        WindowGroup {
            RoutineListView()
                .environment(workoutManager)
                .environment(connectivityManager)
        }
    }
}
