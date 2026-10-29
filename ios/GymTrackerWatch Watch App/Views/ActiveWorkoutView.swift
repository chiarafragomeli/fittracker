import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @State private var selectedTab = 1
    @State private var showingSummary = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ControlsPageView(showingSummary: $showingSummary)
                .tag(0)
            
            MetricsPageView()
                .tag(1)
            
            ExercisePageView(showingSummary: $showingSummary)
                .tag(2)
        }
        .tabViewStyle(.verticalPage)
        .sheet(isPresented: $showingSummary) {
            WorkoutSummaryView()
        }
    }
}
