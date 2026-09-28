import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Lets Dart tell when the iPad app runs on a Mac ("Designed for iPad"),
    // where some native Liquid Glass controls render differently.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppPlatform") {
      let channel = FlutterMethodChannel(
        name: "time_register/platform", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        if call.method == "isiOSAppOnMac" {
          result(ProcessInfo.processInfo.isiOSAppOnMac)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
