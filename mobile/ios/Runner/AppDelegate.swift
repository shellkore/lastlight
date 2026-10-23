import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var lastlightChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LastlightNightBridge") else { return }
    let channel = FlutterMethodChannel(name: "app.lastlight/night", binaryMessenger: registrar.messenger())
    lastlightChannel = channel
    channel.setMethodCallHandler { call, result in
      let defaults = UserDefaults.standard
      switch call.method {
      case "state":
        result([
          "supported": false, "connected": false, "active": false,
          "pending": false, "canClaim": false, "quietSeconds": 0,
          "chapters": 0, "packages": [String](), "automatic": false,
          "startMinute": defaults.object(forKey: "lastlight.startMinute") as? Int ?? 1320,
          "endMinute": defaults.object(forKey: "lastlight.endMinute") as? Int ?? 420,
          "allowance": defaults.object(forKey: "lastlight.allowance") as? Int ?? 20
        ])
      case "apps": result([Any]())
      case "saveSettings":
        let settings = call.arguments as? [String: Any] ?? [:]
        for key in ["startMinute", "endMinute", "allowance"] {
          if let value = settings[key] as? Int { defaults.set(value, forKey: "lastlight." + key) }
        }
        result(nil)
      default:
        result(FlutterError(code: "coming_soon", message: "iOS Screen Time protection is coming soon. This build is a preview.", details: nil))
      }
    }
  }
}
