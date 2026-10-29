import Foundation
import WatchConnectivity
import Observation

@Observable
class ConnectivityManager: NSObject, WCSessionDelegate {
    weak var workoutManager: WorkoutManager?
    var routines: [WatchRoutine] = []
    private let cacheKey = "cached_watch_routines_v2"

    override init() {
        super.init()
        if !loadCachedRoutines() {
            loadFallbackRoutines()
        }
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    private func loadCachedRoutines() -> Bool {
        guard let jsonString = UserDefaults.standard.string(forKey: cacheKey),
              let data = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([WatchRoutine].self, from: data),
              !decoded.isEmpty else {
            return false
        }
        routines = decoded
        return true
    }

    private func applyRoutinesJson(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        do {
            let decoded = try JSONDecoder().decode([WatchRoutine].self, from: data)
            guard !decoded.isEmpty else { return }
            UserDefaults.standard.set(jsonString, forKey: cacheKey)
            DispatchQueue.main.async {
                self.routines = decoded
            }
        } catch {
            print("Error decoding routines: \(error)")
        }
    }

    func requestSyncFromPhone() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if let jsonString = session.receivedApplicationContext["routines"] as? String {
            applyRoutinesJson(jsonString)
        }
        if session.activationState == .activated && session.isReachable {
            session.sendMessage(["request": "syncRoutines"]) { [weak self] reply in
                if let jsonString = reply["routines"] as? String {
                    self?.applyRoutinesJson(jsonString)
                }
            } errorHandler: { _ in }
        }
    }

    private func loadFallbackRoutines() {
        let exMap: [String: (name: String, group: String, metric: String)] = [
            "ex_1": ("Mobilità lower", "Riscaldamento", "duration"),
            "ex_2": ("Mobilità upper", "Riscaldamento", "duration"),
            "ex_3": ("Ponte glutei", "Riscaldamento", "duration"),
            "ex_4": ("Plank", "Core", "duration"),
            "ex_5": ("Crunch al cavo", "Core", "reps"),
            "ex_7": ("Hip thrust", "Gambe", "reps"),
            "ex_8": ("Stacchi rumeni b-stance", "Gambe", "reps"),
            "ex_9": ("Stacchi rumeni", "Gambe", "reps"),
            "ex_10": ("Affondi bulgari", "Gambe", "reps"),
            "ex_11": ("Kickback con extrarotazione", "Gambe", "reps"),
            "ex_12": ("Leg curl", "Gambe", "reps"),
            "ex_13": ("Step up", "Gambe", "reps"),
            "ex_14": ("Slanci laterali al cavo", "Gambe", "reps"),
            "ex_15": ("Calf singolo in piedi", "Gambe", "reps"),
            "ex_16": ("Pulley", "Schiena", "reps"),
            "ex_17": ("Pulley a presa larga", "Schiena", "reps"),
            "ex_18": ("Lat machine prona", "Schiena", "reps"),
            "ex_19": ("Lat machine con triangolo", "Schiena", "reps"),
            "ex_20": ("Rematore singolo su panca", "Schiena", "reps"),
            "ex_21": ("Hyperextension", "Schiena", "reps"),
            "ex_22": ("Spinte con manubri su panca a 75°", "Petto", "reps"),
            "ex_23": ("Alzate laterali", "Spalle", "reps"),
            "ex_24": ("Military press con bilanciere", "Spalle", "reps"),
            "ex_25": ("Curl con bilanciere EZ", "Bicipiti", "reps"),
            "ex_26": ("Curl con manubri in piedi", "Bicipiti", "reps"),
            "ex_27": ("Push down corda", "Tricipiti", "reps"),
            "ex_28": ("French press seduta con manubrio", "Tricipiti", "reps"),
            "ex_29": ("Triceps press cavo alto", "Tricipiti", "reps"),
            "ex_30": ("Stacchi rumeni monopodalici su panca", "Gambe", "reps"),
            "ex_31": ("Affondi su rialzo posteriore multipower", "Gambe", "reps"),
            "ex_32": ("French press con bilanciere EZ", "Tricipiti", "reps"),
            "ex_33": ("Kickback al cavo", "Gambe", "reps"),
            "ex_34": ("Trazioni con elastico", "Schiena", "reps"),
            "ex_35": ("Rematore singolo al cavo", "Schiena", "reps"),
            "ex_36": ("Shoulder press machine", "Spalle", "reps"),
            "ex_37": ("Alzate laterali seduta", "Spalle", "reps"),
            "ex_38": ("Curl ai cavi alti", "Bicipiti", "reps"),
            "ex_39": ("Leg raise alla sbarra", "Core", "reps"),
            "ex_40": ("Kas bridge", "Gambe", "reps"),
            "ex_41": ("Stacchi rumeni al multipower", "Gambe", "reps"),
            "ex_42": ("Rematore presa inversa al cavo", "Schiena", "reps"),
            "ex_43": ("Plank laterale", "Core", "duration"),
            "ex_44": ("Military press con manubri", "Spalle", "reps"),
            "ex_45": ("Crunch su fitball", "Core", "reps"),
            "ex_46": ("Hyperextension gambe flesse", "Gambe", "reps")
        ]

        func makeEx(_ id: String, sets: Int = 3, reps: Int = 10, dur: Int = 30, rest: Int = 90) -> WatchExercise {
            let info = exMap[id] ?? ("Esercizio", "", "reps")
            return WatchExercise(
                id: id,
                name: info.name,
                muscleGroup: info.group,
                metricType: info.metric,
                defaultSets: sets,
                defaultReps: reps,
                defaultDuration: dur,
                restSeconds: rest
            )
        }

        routines = [
            WatchRoutine(
                id: "r_1a",
                name: "Giorno 1A",
                exercises: ["ex_1", "ex_2", "ex_3", "ex_4", "ex_7", "ex_16", "ex_8", "ex_23", "ex_21", "ex_15"].map { makeEx($0) },
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_1b",
                name: "Giorno 1B",
                exercises: ["ex_2", "ex_4", "ex_18", "ex_22", "ex_17", "ex_25", "ex_27", "ex_5"].map { makeEx($0) },
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_1c",
                name: "Giorno 1C",
                exercises: ["ex_1", "ex_3", "ex_4", "ex_9", "ex_7", "ex_10", "ex_11", "ex_12"].map { makeEx($0) },
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_2a",
                name: "Giorno 2A",
                exercises: ["ex_1", "ex_2", "ex_3", "ex_4", "ex_9", "ex_24", "ex_13", "ex_29", "ex_14"].map { makeEx($0) },
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_2b",
                name: "Giorno 2B",
                exercises: ["ex_2", "ex_4", "ex_19", "ex_20", "ex_23", "ex_26", "ex_28", "ex_5"].map { makeEx($0) },
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_2c",
                name: "Giorno 2C",
                exercises: ["ex_1", "ex_3", "ex_4", "ex_7", "ex_30", "ex_31", "ex_21", "ex_11"].map { makeEx($0) },
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_3a",
                name: "Giorno 3A",
                exercises: [
                    makeEx("ex_1", sets: 1, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_2", sets: 1, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_3", sets: 1, reps: 25, dur: 30, rest: 30),
                    makeEx("ex_4", sets: 1, reps: 10, dur: 45, rest: 30),
                    makeEx("ex_7", sets: 3, reps: 5, dur: 30, rest: 120),
                    makeEx("ex_30", sets: 3, reps: 10, dur: 30, rest: 120),
                    makeEx("ex_19", sets: 4, reps: 8, dur: 30, rest: 120),
                    makeEx("ex_32", sets: 3, reps: 12, dur: 30, rest: 90),
                    makeEx("ex_33", sets: 3, reps: 11, dur: 30, rest: 60),
                    makeEx("ex_15", sets: 3, reps: 15, dur: 30, rest: 30)
                ],
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_3b",
                name: "Giorno 3B",
                exercises: [
                    makeEx("ex_2", sets: 1, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_4", sets: 1, reps: 10, dur: 45, rest: 30),
                    makeEx("ex_34", sets: 5, reps: 8, dur: 30, rest: 120),
                    makeEx("ex_35", sets: 3, reps: 8, dur: 30, rest: 90),
                    makeEx("ex_36", sets: 3, reps: 12, dur: 30, rest: 90),
                    makeEx("ex_37", sets: 4, reps: 8, dur: 30, rest: 20),
                    makeEx("ex_23", sets: 4, reps: 10, dur: 30, rest: 90),
                    makeEx("ex_38", sets: 4, reps: 12, dur: 30, rest: 60),
                    makeEx("ex_39", sets: 3, reps: 10, dur: 30, rest: 60)
                ],
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_3c",
                name: "Giorno 3C",
                exercises: [
                    makeEx("ex_1", sets: 1, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_3", sets: 1, reps: 20, dur: 30, rest: 30),
                    makeEx("ex_4", sets: 1, reps: 10, dur: 45, rest: 30),
                    makeEx("ex_9", sets: 4, reps: 8, dur: 30, rest: 150),
                    makeEx("ex_40", sets: 3, reps: 8, dur: 30, rest: 120),
                    makeEx("ex_10", sets: 3, reps: 6, dur: 30, rest: 120),
                    makeEx("ex_12", sets: 3, reps: 8, dur: 30, rest: 120),
                    makeEx("ex_14", sets: 3, reps: 12, dur: 30, rest: 60)
                ],
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_4a",
                name: "Giorno 4A",
                exercises: [
                    makeEx("ex_1", sets: 1, reps: 0, dur: 30, rest: 30),
                    makeEx("ex_2", sets: 1, reps: 0, dur: 30, rest: 30),
                    makeEx("ex_3", sets: 1, reps: 25, dur: 30, rest: 30),
                    makeEx("ex_4", sets: 1, reps: 0, dur: 45, rest: 30),
                    makeEx("ex_41", sets: 4, reps: 6, dur: 0, rest: 150),
                    makeEx("ex_7", sets: 3, reps: 7, dur: 0, rest: 120),
                    makeEx("ex_22", sets: 3, reps: 6, dur: 0, rest: 120),
                    makeEx("ex_42", sets: 3, reps: 8, dur: 0, rest: 90),
                    makeEx("ex_14", sets: 3, reps: 14, dur: 0, rest: 90),
                    makeEx("ex_15", sets: 3, reps: 15, dur: 0, rest: 30)
                ],
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_4b",
                name: "Giorno 4B",
                exercises: [
                    makeEx("ex_2", sets: 1, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_43", sets: 2, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_18", sets: 4, reps: 12, dur: 30, rest: 120),
                    makeEx("ex_44", sets: 3, reps: 6, dur: 30, rest: 20),
                    makeEx("ex_23", sets: 3, reps: 10, dur: 30, rest: 150),
                    makeEx("ex_27", sets: 4, reps: 8, dur: 30, rest: 90),
                    makeEx("ex_25", sets: 4, reps: 6, dur: 30, rest: 90),
                    makeEx("ex_45", sets: 3, reps: 15, dur: 30, rest: 90)
                ],
                healthActivityType: "traditionalStrengthTraining"
            ),
            WatchRoutine(
                id: "r_4c",
                name: "Giorno 4C",
                exercises: [
                    makeEx("ex_1", sets: 1, reps: 10, dur: 30, rest: 30),
                    makeEx("ex_3", sets: 1, reps: 20, dur: 30, rest: 30),
                    makeEx("ex_4", sets: 1, reps: 10, dur: 45, rest: 30),
                    makeEx("ex_8", sets: 3, reps: 6, dur: 30, rest: 150),
                    makeEx("ex_13", sets: 3, reps: 8, dur: 30, rest: 120),
                    makeEx("ex_46", sets: 3, reps: 8, dur: 30, rest: 120),
                    makeEx("ex_12", sets: 3, reps: 10, dur: 30, rest: 90),
                    makeEx("ex_11", sets: 2, reps: 12, dur: 30, rest: 90)
                ],
                healthActivityType: "traditionalStrengthTraining"
            )
        ]
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        if let jsonString = session.receivedApplicationContext["routines"] as? String {
            applyRoutinesJson(jsonString)
        }
        requestSyncFromPhone()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            requestSyncFromPhone()
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let jsonString = applicationContext["routines"] as? String {
            applyRoutinesJson(jsonString)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let jsonString = message["routines"] as? String {
            applyRoutinesJson(jsonString)
            return
        }
        let type = message["type"] as? String ?? ""
        if type == "workoutStarted" {
            let routineId = message["routineId"] as? String ?? ""
            let workoutId = message["workoutId"] as? String ?? ""
            if let routine = routines.first(where: { $0.id == routineId }) {
                DispatchQueue.main.async { [weak self] in
                    guard let wm = self?.workoutManager else { return }
                    if !wm.isRunning {
                        Task {
                            try? await wm.requestAuthorization()
                            try? await wm.startWorkout(routine: routine, customId: workoutId)
                        }
                    }
                }
            }
        } else if type == "workoutDiscarded" {
            DispatchQueue.main.async { [weak self] in
                self?.workoutManager?.discardWorkout()
            }
        } else if type == "setCompleted" {
            let exerciseId = message["exerciseId"] as? String ?? ""
            let setIndex = (message["setIndex"] as? Int) ?? 0
            let weight = (message["weight"] as? Double) ?? 0.0
            let reps = (message["reps"] as? Int) ?? 0
            let durationSeconds = (message["durationSeconds"] as? Int) ?? 0
            let restSeconds = (message["restSeconds"] as? Int) ?? 0
            DispatchQueue.main.async { [weak self] in
                self?.workoutManager?.completeSetFromPhone(
                    exerciseId: exerciseId,
                    setIndex: setIndex,
                    weight: weight,
                    reps: reps,
                    durationSeconds: durationSeconds,
                    restSeconds: restSeconds
                )
            }
        }
    }

    func sendSetCompleted(
        workoutId: String,
        exerciseId: String,
        exerciseName: String,
        setIndex: Int,
        weight: Double,
        reps: Int,
        durationSeconds: Int,
        restSeconds: Int,
        nextExerciseName: String,
        nextSetInfo: String
    ) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            "type": "setCompleted",
            "workoutId": workoutId,
            "exerciseId": exerciseId,
            "exerciseName": exerciseName,
            "setIndex": setIndex,
            "weight": weight,
            "reps": reps,
            "durationSeconds": durationSeconds,
            "restSeconds": restSeconds,
            "nextExerciseName": nextExerciseName,
            "nextSetInfo": nextSetInfo,
            "timestampMs": Int(Date().timeIntervalSince1970 * 1000)
        ]
        let session = WCSession.default
        if session.activationState == .activated {
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { _ in
                    session.transferUserInfo(payload)
                }
            } else {
                session.transferUserInfo(payload)
            }
        } else {
            session.activate()
        }
    }

    func sendWorkoutStarted(workoutId: String, routineId: String, routineName: String, startTimeMs: Int) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            "type": "workoutStarted",
            "workoutId": workoutId,
            "id": workoutId,
            "routineId": routineId,
            "routineName": routineName,
            "startTimeMs": startTimeMs
        ]
        let session = WCSession.default
        if session.activationState == .activated {
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { _ in
                    session.transferUserInfo(payload)
                }
            } else {
                session.transferUserInfo(payload)
            }
        } else {
            session.activate()
        }
    }

    func sendWorkoutDiscarded(workoutId: String) {
        guard WCSession.isSupported() else { return }
        let payload: [String: Any] = [
            "type": "workoutDiscarded",
            "workoutId": workoutId
        ]
        let session = WCSession.default
        if session.activationState == .activated {
            if session.isReachable {
                session.sendMessage(payload, replyHandler: nil) { _ in
                    session.transferUserInfo(payload)
                }
            } else {
                session.transferUserInfo(payload)
            }
        } else {
            session.activate()
        }
    }

    private var sentCompletedWorkoutIds: Set<String> = []

    func sendCompletedWorkout(data: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        var payload = data
        payload["type"] = "workoutCompleted"

        let workoutId = (payload["id"] as? String) ?? (payload["workoutId"] as? String) ?? ""
        if !workoutId.isEmpty {
            if sentCompletedWorkoutIds.contains(workoutId) {
                return // Prevent duplicate sending
            }
            sentCompletedWorkoutIds.insert(workoutId)
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }
}
