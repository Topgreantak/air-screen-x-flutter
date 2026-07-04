import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        // Register our native display plugin (manual — not a pub plugin).
        if let registrar = registrar(forPlugin: "DisplayPlugin") {
            DisplayPlugin.register(with: registrar)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
