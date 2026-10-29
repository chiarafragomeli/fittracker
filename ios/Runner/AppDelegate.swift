import Flutter
import UIKit
import AudioToolbox
import WatchConnectivity
import ActivityKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
  private var watchChannel: FlutterMethodChannel?
  private var pendingWatchContext: [String: Any]?
  private var latestWatchContext: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Request notification authorization for workout banners
    UNUserNotificationCenter.current().delegate = self
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    
    let messenger: FlutterBinaryMessenger? =
      self.registrar(forPlugin: "GymTrackerNativeChannels")?.messenger()
      ?? (window?.rootViewController as? FlutterViewController)?.binaryMessenger

    if let binaryMessenger = messenger {
      // Sound channel
      let soundChannel = FlutterMethodChannel(name: "gym_tracker/sound", binaryMessenger: binaryMessenger)
      soundChannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if call.method == "playRestDone" {
          AudioServicesPlaySystemSound(1052)
          result(true)
        } else if call.method == "playClick" {
          AudioServicesPlaySystemSound(1104)
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
      
      // Watch Connectivity channel
      watchChannel = FlutterMethodChannel(name: "gym_tracker/watch", binaryMessenger: binaryMessenger)
      watchChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "syncRoutinesToWatch":
          if let args = call.arguments as? [String: Any] {
            self?.syncToWatch(args, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        case "shareFile":
          if let args = call.arguments as? [String: Any],
             let filePath = args["path"] as? String {
            self?.shareFile(at: filePath, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected file path", details: nil))
          }
        case "startWorkoutOnWatch":
          if let args = call.arguments as? [String: Any] {
            var payload = args
            payload["type"] = "workoutStarted"
            if WCSession.isSupported() && WCSession.default.activationState == .activated && WCSession.default.isReachable {
              WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        case "endWorkoutOnWatch":
          if let args = call.arguments as? [String: Any] {
            var payload = args
            payload["type"] = "workoutDiscarded"
            if WCSession.isSupported() && WCSession.default.activationState == .activated && WCSession.default.isReachable {
              WCSession.default.sendMessage(payload, replyHandler: nil, errorHandler: nil)
            }
            if #available(iOS 16.1, *) {
              LiveActivityManager.shared.endLiveActivity()
            }
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        case "syncSetToWatch":
          if let args = call.arguments as? [String: Any] {
            var payload = args
            payload["type"] = "setCompleted"
            if WCSession.isSupported() && WCSession.default.activationState == .activated {
              if WCSession.default.isReachable {
                WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                  WCSession.default.transferUserInfo(payload)
                }
              } else {
                WCSession.default.transferUserInfo(payload)
              }
            }
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        case "startLiveActivity":
          if let args = call.arguments as? [String: Any] {
            let wId = (args["workoutId"] as? String) ?? "workout_\(Int(Date().timeIntervalSince1970 * 1000))"
            let rName = (args["routineName"] as? String) ?? "Allenamento"
            let exName = (args["exerciseName"] as? String) ?? ""
            let setInfo = (args["setInfo"] as? String) ?? ""
            let sTimeMs = (args["startTimeMs"] as? Int) ?? Int(Date().timeIntervalSince1970 * 1000)
            let sDate = Date(timeIntervalSince1970: Double(sTimeMs) / 1000.0)
            if #available(iOS 16.1, *) {
              LiveActivityManager.shared.startLiveActivity(
                workoutId: wId,
                routineName: rName,
                exerciseName: exName,
                setInfo: setInfo,
                startDate: sDate
              )
            }
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        case "updateLiveActivity":
          if let args = call.arguments as? [String: Any] {
            let exName = (args["exerciseName"] as? String) ?? ""
            let setInfo = (args["setInfo"] as? String) ?? ""
            let isPaused = (args["isPaused"] as? Bool) ?? false
            if #available(iOS 16.1, *) {
              LiveActivityManager.shared.updateLiveActivity(exerciseName: exName, setInfo: setInfo, isPaused: isPaused)
            }
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        case "endLiveActivity":
          if #available(iOS 16.1, *) {
            LiveActivityManager.shared.endLiveActivity()
          }
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      })
    }

    // Activate WatchConnectivity unconditionally on launch
    if WCSession.isSupported() {
      let session = WCSession.default
      session.delegate = self
      session.activate()
    }

    return result
  }

  // MARK: - Share file via iOS Share Sheet
  private func shareFile(at path: String, result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      let fileURL = URL(fileURLWithPath: path)
      let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

      let keyWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow } ?? self?.window

      guard var topController = keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_ROOT_VC", message: "Could not find root view controller", details: nil))
        return
      }
      while let presented = topController.presentedViewController {
        topController = presented
      }

      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = topController.view
        popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
      }

      topController.present(activityVC, animated: true) {
        result(true)
      }
    }
  }
  
  // MARK: - Sync routines to Watch
  private func syncToWatch(_ data: [String: Any], result: @escaping FlutterResult) {
    latestWatchContext = data
    if let routinesJson = data["routines"] as? String {
      UserDefaults.standard.set(routinesJson, forKey: "last_synced_watch_routines")
    }
    guard WCSession.isSupported() else {
      result(false)
      return
    }
    guard WCSession.default.activationState == .activated else {
      pendingWatchContext = data
      WCSession.default.activate()
      result(true)
      return
    }

    do {
      try WCSession.default.updateApplicationContext(data)
      if WCSession.default.isReachable {
        WCSession.default.sendMessage(data, replyHandler: nil, errorHandler: nil)
      }
      pendingWatchContext = nil
      result(true)
    } catch {
      result(FlutterError(code: "SYNC_FAIL", message: error.localizedDescription, details: nil))
    }
  }
  
  // MARK: - WCSessionDelegate
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let error = error {
      print("WCSession activation failed: \(error.localizedDescription)")
      return
    }
    if activationState == .activated {
      let contextToPush = pendingWatchContext ?? latestWatchContext
      if let pending = contextToPush {
        try? session.updateApplicationContext(pending)
        if session.isReachable {
          session.sendMessage(pending, replyHandler: nil, errorHandler: nil)
        }
        pendingWatchContext = nil
      }
    }
  }

  func sessionWatchStateDidChange(_ session: WCSession) {
    if session.activationState == .activated, session.isWatchAppInstalled {
      if let context = latestWatchContext ?? (UserDefaults.standard.string(forKey: "last_synced_watch_routines").map { ["routines": $0] }) {
        try? session.updateApplicationContext(context)
      }
    }
  }
  
  func sessionDidBecomeInactive(_ session: WCSession) {}
  
  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }
  
  private var processedWorkoutIds = Set<String>()
  private var activeLiveActivityWorkoutId: String?

  private func handleIncomingWatchPayload(_ payload: [String: Any]) {
    let type = payload["type"] as? String ?? ""
    if type == "workoutStarted" {
      let workoutId = (payload["workoutId"] as? String) ?? (payload["id"] as? String) ?? "workout_\(Int(Date().timeIntervalSince1970 * 1000))"
      let routineName = (payload["routineName"] as? String) ?? (payload["name"] as? String) ?? "Allenamento"
      let startTimeMs = (payload["startTimeMs"] as? Int) ?? Int(Date().timeIntervalSince1970 * 1000)
      let startDate = Date(timeIntervalSince1970: Double(startTimeMs) / 1000.0)

      if activeLiveActivityWorkoutId == workoutId {
        return // Already active for this workout
      }
      activeLiveActivityWorkoutId = workoutId

      if #available(iOS 16.1, *) {
        LiveActivityManager.shared.startLiveActivity(
          workoutId: workoutId,
          routineName: routineName,
          startDate: startDate
        )
        LiveActivityManager.shared.postWorkoutNotification(routineName: routineName)
      }

      DispatchQueue.main.async { [weak self] in
        self?.watchChannel?.invokeMethod("onWorkoutStarted", arguments: payload)
      }
      return
    }
    if type == "workoutDiscarded" {
      activeLiveActivityWorkoutId = nil
      if #available(iOS 16.1, *) {
        LiveActivityManager.shared.endLiveActivity()
      }
      DispatchQueue.main.async { [weak self] in
        self?.watchChannel?.invokeMethod("onWorkoutDiscarded", arguments: payload)
      }
      return
    }
    if type == "setCompleted" {
      let exerciseName = (payload["nextExerciseName"] as? String) ?? (payload["exerciseName"] as? String) ?? ""
      let setInfo = (payload["nextSetInfo"] as? String) ?? ""

      if #available(iOS 16.1, *) {
        LiveActivityManager.shared.updateLiveActivity(exerciseName: exerciseName, setInfo: setInfo)
      }

      DispatchQueue.main.async { [weak self] in
        self?.watchChannel?.invokeMethod("onSetCompleted", arguments: payload)
      }
      return
    }

    // Workout completed handling with deduplication
    let workoutId = (payload["workoutId"] as? String) ?? (payload["id"] as? String) ?? ""
    if !workoutId.isEmpty {
      if processedWorkoutIds.contains(workoutId) {
        return // Already processed this workout completed event
      }
      processedWorkoutIds.insert(workoutId)
    }

    activeLiveActivityWorkoutId = nil
    if #available(iOS 16.1, *) {
      LiveActivityManager.shared.endLiveActivity()
    }

    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod("onWorkoutCompleted", arguments: payload)
    }
  }

  // Receive completed workout from Watch (background transferUserInfo)
  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    handleIncomingWatchPayload(userInfo)
  }

  // Receive message from Watch (live sendMessage without reply)
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    if message["request"] as? String == "syncRoutines" {
      if let context = latestWatchContext
          ?? (session.applicationContext["routines"] != nil ? session.applicationContext : nil)
          ?? (UserDefaults.standard.string(forKey: "last_synced_watch_routines").map { ["routines": $0] }) {
        try? session.updateApplicationContext(context)
        if session.isReachable {
          session.sendMessage(context, replyHandler: nil, errorHandler: nil)
        }
      }
      return
    }
    handleIncomingWatchPayload(message)
  }

  // Receive message from Watch (live sendMessage with replyHandler)
  func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
    if message["request"] as? String == "syncRoutines" {
      let context = latestWatchContext
        ?? (session.applicationContext["routines"] != nil ? session.applicationContext : nil)
        ?? (UserDefaults.standard.string(forKey: "last_synced_watch_routines").map { ["routines": $0] })
        ?? [:]
      replyHandler(context)
      return
    }
    handleIncomingWatchPayload(message)
    replyHandler(["status": "ok"])
  }

  // MARK: - UNUserNotificationCenterDelegate (Foreground notifications)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge, .list])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}

// MARK: - ActivityKit Live Activity & Notification Support

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

@available(iOS 16.1, *)
class LiveActivityManager {
  static let shared = LiveActivityManager()
  private var currentActivity: Activity<WorkoutActivityAttributes>?

  func startLiveActivity(
    workoutId: String,
    routineName: String,
    exerciseName: String = "",
    setInfo: String = "",
    startDate: Date = Date()
  ) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      print("Live Activities are not enabled by user")
      return
    }
    endLiveActivity()
    let attributes = WorkoutActivityAttributes(workoutId: workoutId)
    let initialContentState = WorkoutActivityAttributes.ContentState(
      routineName: routineName,
      exerciseName: exerciseName,
      setInfo: setInfo,
      isPaused: false,
      startDate: startDate
    )
    do {
      if #available(iOS 16.2, *) {
        let content = ActivityContent(state: initialContentState, staleDate: nil)
        currentActivity = try Activity<WorkoutActivityAttributes>.request(
          attributes: attributes,
          content: content,
          pushType: nil
        )
      } else {
        currentActivity = try Activity<WorkoutActivityAttributes>.request(
          attributes: attributes,
          contentState: initialContentState,
          pushType: nil
        )
      }
      print("Live Activity started successfully for workout: \(workoutId)")
    } catch {
      print("Failed to start Live Activity: \(error)")
    }
  }

  func updateLiveActivity(exerciseName: String, setInfo: String, isPaused: Bool = false) {
    guard let activity = currentActivity else { return }
    let currentRoutineName: String
    let currentStartDate: Date
    if #available(iOS 16.2, *) {
      currentRoutineName = activity.content.state.routineName
      currentStartDate = activity.content.state.startDate
    } else {
      currentRoutineName = activity.contentState.routineName
      currentStartDate = activity.contentState.startDate
    }
    let updatedState = WorkoutActivityAttributes.ContentState(
      routineName: currentRoutineName,
      exerciseName: exerciseName,
      setInfo: setInfo,
      isPaused: isPaused,
      startDate: currentStartDate
    )
    Task {
      if #available(iOS 16.2, *) {
        let content = ActivityContent(state: updatedState, staleDate: nil)
        await activity.update(content)
      } else {
        await activity.update(using: updatedState)
      }
    }
  }

  func endLiveActivity() {
    guard let activity = currentActivity else { return }
    Task {
      if #available(iOS 16.2, *) {
        await activity.end(nil, dismissalPolicy: .immediate)
      } else {
        await activity.end(dismissalPolicy: .immediate)
      }
      self.currentActivity = nil
    }
  }

  func postWorkoutNotification(routineName: String) {
    let content = UNMutableNotificationContent()
    content.title = "Allenamento Avviato"
    content.body = "Scheda: \(routineName) — In sincronizzazione con Apple Watch."
    content.sound = .default
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(
      identifier: "workout_started_\(Date().timeIntervalSince1970)",
      content: content,
      trigger: trigger
    )
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }
}
