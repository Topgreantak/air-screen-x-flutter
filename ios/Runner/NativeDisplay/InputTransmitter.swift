import Foundation
import Network

// Touch/input sender (UDP 7655 → Windows). Serializes IDIP packets (matches protocol.hpp).
// NOTE: not built here (needs macOS/Xcode).

struct TouchPoint { let id: UInt8; let normX: Float; let normY: Float }

struct InputPacket {
    enum EventType: UInt8 { case down = 0x01, move = 0x02, up = 0x03, scroll = 0x04 }
    let type: EventType
    let touches: [TouchPoint]
    let timestampUs: UInt64
}

final class InputTransmitter {
    private let conn: NWConnection

    init(hostIp: String, port: UInt16) {
        conn = NWConnection(host: NWEndpoint.Host(hostIp),
                            port: NWEndpoint.Port(rawValue: port)!, using: .udp)
        conn.start(queue: .global(qos: .userInteractive))
    }

    func stop() { conn.cancel() }

    func send(_ pkt: InputPacket) {
        var d = Data()
        appendBE32(&d, 0x49444950)                 // "IDIP"
        appendBE64(&d, pkt.timestampUs)
        d.append(pkt.type.rawValue)
        d.append(UInt8(min(pkt.touches.count, 255)))
        for t in pkt.touches.prefix(255) {
            d.append(t.id)
            appendBE32(&d, t.normX.bitPattern)
            appendBE32(&d, t.normY.bitPattern)
        }
        conn.send(content: d, completion: .contentProcessed { _ in })
    }

    private func appendBE32(_ d: inout Data, _ v: UInt32) {
        d.append(UInt8((v >> 24) & 0xFF)); d.append(UInt8((v >> 16) & 0xFF))
        d.append(UInt8((v >> 8) & 0xFF));  d.append(UInt8(v & 0xFF))
    }
    private func appendBE64(_ d: inout Data, _ v: UInt64) {
        for i in stride(from: 56, through: 0, by: -8) { d.append(UInt8((v >> UInt64(i)) & 0xFF)) }
    }
}
