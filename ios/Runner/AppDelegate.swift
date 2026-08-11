import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    if let controller = window?.rootViewController as? FlutterViewController {
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
    }

    return result
  }
}
