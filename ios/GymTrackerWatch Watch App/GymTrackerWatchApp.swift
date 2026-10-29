import SwiftUI

@main
struct GymTrackerWatchApp: App {
    @State private var workoutManager: WorkoutManager
    @State private var connectivityManager: ConnectivityManager

    init() {
        let wm = WorkoutManager()
        let cm = ConnectivityManager()
        wm.connectivityManager = cm
        cm.workoutManager = wm
        _workoutManager = State(initialValue: wm)
        _connectivityManager = State(initialValue: cm)
    }

    var body: some Scene {
        WindowGroup {
            RoutineListView()
                .environment(workoutManager)
                .environment(connectivityManager)
        }
    }
}
