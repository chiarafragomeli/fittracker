import ActivityKit
import WidgetKit
import SwiftUI

@main
struct MyGymBroWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen / Notification banner presentation
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "dumbbell.fill")
                            .foregroundColor(.orange)
                        Text(context.state.routineName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundColor(.green)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        if !context.state.exerciseName.isEmpty {
                            Text(context.state.exerciseName)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                        if !context.state.setInfo.isEmpty {
                            Text(context.state.setInfo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.orange)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                    .font(.caption2.bold())
                    .monospacedDigit()
                    .foregroundColor(.green)
                    .frame(width: 44)
            } minimal: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.orange)
            }
            .contentMargins(.all, 8, for: .expanded)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.routineName)
                    .font(.headline)
                    .foregroundColor(.white)
                if !context.state.exerciseName.isEmpty {
                    Text(context.state.exerciseName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text("Allenamento in corso")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                if !context.state.setInfo.isEmpty {
                    Text(context.state.setInfo)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(timerInterval: context.state.startDate...Date.distantFuture, countsDown: false)
                    .font(.title2.bold())
                    .monospacedDigit()
                    .foregroundColor(.green)
                if context.state.isPaused {
                    Text("IN PAUSA")
                        .font(.caption2.bold())
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.85))
    }
}
