import Foundation

struct WatchExercise: Identifiable, Codable {
    let id: String
    let name: String
    let muscleGroup: String
    let metricType: String  // "reps" or "duration"
    let defaultSets: Int
    let defaultReps: Int
    let defaultDuration: Int  // seconds
    let restSeconds: Int
}
