import Foundation
import CoreVideo

// Shared native session: ties the ctrl handshake, video receive+decode, and input send together.
// The plugin owns one; the Metal view binds its renderer to `decoder`. Not built here.

final class DisplaySession {
    let decoder = VideoDecoder()
    private(set) var input: InputTransmitter?
    private var ctrl: CtrlClient?
    private var stream: StreamClient?

    // Called with native status events (paired/denied/idle/resume/...) → forwarded to Flutter.
    var onStatus: (([String: Any]) -> Void)?
    // Called when a decoded frame is ready (renderer binds here).
    var onFrame: ((CVPixelBuffer) -> Void)?
    // Latest stream size for the renderer's letterbox layout.
    private(set) var streamSize: CGSize = .zero

    func start(hostIp: String, prefs: [String: Any], deviceName: String, deviceId: String) {
        decoder.configure { [weak self] pb, _ in self?.onFrame?(pb) }

        input  = InputTransmitter(hostIp: hostIp, port: 7655)
        stream = StreamClient(hostIp: hostIp, port: 7654) { [weak self] nal, _ in
            self?.decoder.decodeNAL(nal)   // VT thread; decoder is internally serialized
        }
        stream?.start()

        ctrl = CtrlClient(hostIp: hostIp, port: 7656, prefs: prefs) { [weak self] status in
            if let cfg = status["config"] as? [String: Any],
               let w = cfg["virtualWidth"] as? Int, let h = cfg["virtualHeight"] as? Int {
                self?.streamSize = CGSize(width: w, height: h)
            }
            self?.onStatus?(status)
        }
        ctrl?.start(deviceName: deviceName, deviceId: deviceId)
    }

    func updatePrefs(_ prefs: [String: Any]) { ctrl?.updatePrefs(prefs) }

    func stop() {
        ctrl?.disconnect(); ctrl = nil
        stream?.stop();     stream = nil
        input?.stop();      input = nil
        decoder.invalidate()
    }

    deinit { stop() }
}
