import Foundation

struct WatchRoutine: Identifiable, Codable {
    let id: String
    let name: String
    let exercises: [WatchExercise]
    let healthActivityType: String?
}
