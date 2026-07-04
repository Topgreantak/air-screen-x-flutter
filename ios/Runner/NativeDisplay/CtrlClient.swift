import Foundation
import Network

// Control channel (TCP 7656). R6: iOS initiates — sends PAIR_REQUEST, waits for Accept/Deny,
// keeps the sessionToken, then SET_PREFS. Parses CONFIG_ACK / CONFIG_UPDATE / STREAM_IDLE/RESUME.
// NOTE: not built here (needs macOS/Xcode). Uses Network.framework (R2 — no raw BSD sockets).

final class CtrlClient {
    typealias StatusHandler = ([String: Any]) -> Void

    private let host: NWEndpoint.Host
    private let conn: NWConnection
    private let onStatus: StatusHandler
    private var buffer = Data()

    private(set) var sessionToken: String?
    private var pendingPrefs: [String: Any]

    init(hostIp: String, port: UInt16, prefs: [String: Any], onStatus: @escaping StatusHandler) {
        self.host = NWEndpoint.Host(hostIp)
        self.conn = NWConnection(host: self.host, port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        self.onStatus = onStatus
        self.pendingPrefs = prefs
    }

    func start(deviceName: String, deviceId: String) {
        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .ready = state {
                self.send(["type": "PAIR_REQUEST", "deviceName": deviceName, "deviceId": deviceId])
                self.receiveLoop()
            } else if case .failed = state {
                self.onStatus(["event": "error"])
            }
        }
        conn.start(queue: .global(qos: .userInitiated))
    }

    func updatePrefs(_ prefs: [String: Any]) {
        pendingPrefs = prefs
        guard let token = sessionToken else { return }
        var msg = prefs; msg["type"] = "SET_PREFS"; msg["sessionToken"] = token
        send(msg)
    }

    func disconnect() {
        if let token = sessionToken { send(["type": "DISCONNECT", "sessionToken": token]) }
        conn.cancel()
    }

    // MARK: - IO

    private func send(_ obj: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: obj) else { return }
        var line = data; line.append(0x0A) // newline-delimited
        conn.send(content: line, completion: .contentProcessed { _ in })
    }

    private func receiveLoop() {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, done, err in
            guard let self else { return }
            if let data, !data.isEmpty { self.buffer.append(data); self.drainLines() }
            if err != nil || done { self.onStatus(["event": "disconnected"]); return }
            self.receiveLoop()
        }
    }

    private func drainLines() {
        while let nl = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer.subdata(in: buffer.startIndex..<nl)
            buffer.removeSubrange(buffer.startIndex...nl)
            guard let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let type = obj["type"] as? String else { continue }
            handle(type: type, obj: obj)
        }
    }

    private func handle(type: String, obj: [String: Any]) {
        switch type {
        case "PAIR_ACCEPT":
            sessionToken = obj["sessionToken"] as? String
            // Send the prefs the user picked now that we're paired (R1).
            updatePrefs(pendingPrefs)
        case "PAIR_DENY":
            onStatus(["event": "denied", "reason": obj["reason"] as? String ?? "denied"])
        case "CONFIG_ACK", "CONFIG_UPDATE":
            onStatus(["event": "paired", "config": obj])
        case "STREAM_IDLE":
            onStatus(["event": "idle"])   // R4: renderer pauses
        case "STREAM_RESUME":
            onStatus(["event": "resume"])
        case "PING":
            if let token = sessionToken {
                send(["type": "PONG", "sessionToken": token, "ts": obj["ts"] ?? 0])
            }
        default:
            break
        }
    }
}
