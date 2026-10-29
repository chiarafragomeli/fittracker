import Foundation
import ActivityKit

public struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var routineName: String
        public var exerciseName: String
        public var setInfo: String
        public var isPaused: Bool
        public var startDate: Date

        public init(
            routineName: String,
            exerciseName: String = "",
            setInfo: String = "",
            isPaused: Bool = false,
            startDate: Date = Date()
        ) {
            self.routineName = routineName
            self.exerciseName = exerciseName
            self.setInfo = setInfo
            self.isPaused = isPaused
            self.startDate = startDate
        }
    }

    public var workoutId: String

    public init(workoutId: String) {
        self.workoutId = workoutId
    }
}
