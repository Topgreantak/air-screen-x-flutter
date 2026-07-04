import Flutter
import UIKit

// Flutter plugin entry. Bridges Dart (DisplayChannel) ↔ native session, and registers the
// Metal platform view. R6: startStream triggers the PAIR_REQUEST handshake. Not built here.

@objc class DisplayPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private let session = DisplaySession()
    private var eventSink: FlutterEventSink?

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DisplayPlugin()

        let method = FlutterMethodChannel(name: "idisplay/native", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: method)

        let events = FlutterEventChannel(name: "idisplay/status", binaryMessenger: registrar.messenger())
        events.setStreamHandler(instance)

        let factory = MetalViewFactory(session: instance.session)
        registrar.register(factory, withId: "idisplay/metal-view")

        instance.session.onStatus = { [weak instance] status in
            DispatchQueue.main.async { instance?.eventSink?(status) }
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startStream":
            guard let args = call.arguments as? [String: Any],
                  let hostIp = args["hostIp"] as? String, !hostIp.isEmpty else {
                result(FlutterError(code: "NO_HOST", message: "hostIp required", details: nil)); return
            }
            var prefs = args; prefs.removeValue(forKey: "hostIp")
            let name = UIDevice.current.name
            let id = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
            session.start(hostIp: hostIp, prefs: prefs, deviceName: name, deviceId: id)
            result(nil)

        case "updateConfig":
            if let prefs = call.arguments as? [String: Any] { session.updatePrefs(prefs) }
            result(nil)

        case "stopStream":
            session.stop()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // FlutterStreamHandler
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events; return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil; return nil
    }
}
