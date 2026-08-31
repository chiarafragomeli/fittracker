import Foundation
import WatchConnectivity
import Observation

@Observable
class ConnectivityManager: NSObject, WCSessionDelegate {
    var routines: [WatchRoutine] = []

    override init() {
        super.init()
        loadFallbackRoutines()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    private func loadFallbackRoutines() {
        let exercises = [
            WatchExercise(id: "1", name: "Mobilità lower", muscleGroup: "Gambe", metricType: "duration", defaultSets: 1, defaultReps: 0, defaultDuration: 300, restSeconds: 0),
            WatchExercise(id: "2", name: "Mobilità upper", muscleGroup: "Dorso/Petto", metricType: "duration", defaultSets: 1, defaultReps: 0, defaultDuration: 300, restSeconds: 0),
            WatchExercise(id: "3", name: "Ponte glutei", muscleGroup: "Glutei", metricType: "duration", defaultSets: 3, defaultReps: 0, defaultDuration: 60, restSeconds: 60),
            WatchExercise(id: "4", name: "Plank", muscleGroup: "Addome", metricType: "duration", defaultSets: 3, defaultReps: 0, defaultDuration: 45, restSeconds: 60),
            WatchExercise(id: "5", name: "Hip thrust", muscleGroup: "Glutei", metricType: "reps", defaultSets: 3, defaultReps: 10, defaultDuration: 0, restSeconds: 90),
            WatchExercise(id: "6", name: "Pulley", muscleGroup: "Dorso", metricType: "reps", defaultSets: 3, defaultReps: 10, defaultDuration: 0, restSeconds: 90),
            WatchExercise(id: "7", name: "Stacchi rumeni b-stance", muscleGroup: "Femorali", metricType: "reps", defaultSets: 3, defaultReps: 10, defaultDuration: 0, restSeconds: 90),
            WatchExercise(id: "8", name: "Alzate laterali", muscleGroup: "Spalle", metricType: "reps", defaultSets: 3, defaultReps: 12, defaultDuration: 0, restSeconds: 60),
            WatchExercise(id: "9", name: "Hyperextension", muscleGroup: "Lombari", metricType: "reps", defaultSets: 3, defaultReps: 12, defaultDuration: 0, restSeconds: 60),
            WatchExercise(id: "10", name: "Calf singolo in piedi", muscleGroup: "Polpacci", metricType: "reps", defaultSets: 3, defaultReps: 15, defaultDuration: 0, restSeconds: 60)
        ]
        routines = [WatchRoutine(id: "r1", name: "Giorno 1A", exercises: exercises, healthActivityType: "traditionalStrengthTraining")]
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let jsonString = applicationContext["routines"] as? String,
           let data = jsonString.data(using: .utf8) {
            do {
                let decoded = try JSONDecoder().decode([WatchRoutine].self, from: data)
                DispatchQueue.main.async {
                    self.routines = decoded
                }
            } catch {
                print("Error decoding routines: \(error)")
            }
        }
    }

    func sendCompletedWorkout(data: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.transferUserInfo(data)
        }
    }
}
