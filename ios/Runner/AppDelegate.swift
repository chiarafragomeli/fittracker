import Flutter
import UIKit
import AudioToolbox
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {
  private var watchChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController as? FlutterViewController {
      // Sound channel
      let soundChannel = FlutterMethodChannel(name: "gym_tracker/sound", binaryMessenger: controller.binaryMessenger)
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
      watchChannel = FlutterMethodChannel(name: "gym_tracker/watch", binaryMessenger: controller.binaryMessenger)
      watchChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "syncRoutinesToWatch":
          if let args = call.arguments as? [String: Any] {
            self?.syncToWatch(args, result: result)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected dictionary", details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      })
      
      // Activate WatchConnectivity
      if WCSession.isSupported() {
        let session = WCSession.default
        session.delegate = self
        session.activate()
      }
    }

    return result
  }
  
  // MARK: - Sync routines to Watch
  private func syncToWatch(_ data: [String: Any], result: @escaping FlutterResult) {
    guard WCSession.default.activationState == .activated else {
      result(FlutterError(code: "NOT_ACTIVATED", message: "WCSession not activated", details: nil))
      return
    }
    
    do {
      try WCSession.default.updateApplicationContext(data)
      result(true)
    } catch {
      result(FlutterError(code: "SYNC_FAIL", message: error.localizedDescription, details: nil))
    }
  }
  
  // MARK: - WCSessionDelegate
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    if let error = error {
      print("WCSession activation failed: \(error.localizedDescription)")
    }
  }
  
  func sessionDidBecomeInactive(_ session: WCSession) {}
  
  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }
  
  // Receive completed workout from Watch
  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    DispatchQueue.main.async { [weak self] in
      self?.watchChannel?.invokeMethod("onWorkoutCompleted", arguments: userInfo)
    }
  }
}
