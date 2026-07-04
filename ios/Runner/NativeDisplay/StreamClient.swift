import Foundation
import Network

// Video receiver (UDP 7654). Reassembles IDSP chunks into full frames and feeds NAL units to
// the decoder. NOTE: not built here (needs macOS/Xcode). Network.framework, no raw sockets (R2).

final class StreamClient {
    private var listener: NWConnection?
    private let port: UInt16
    private let onNAL: (Data, Bool) -> Void   // (nalPayload, isKeyFrame)

    // Reassembly: frameId → collected chunks.
    private var frames: [UInt32: [Int: Data]] = [:]
    private var frameChunkCount: [UInt32: Int] = [:]
    private let lock = NSLock()

    init(hostIp: String, port: UInt16, onNAL: @escaping (Data, Bool) -> Void) {
        self.port = port
        self.onNAL = onNAL
        // UDP is connectionless; we bind a receiver. The host learns our address from the ctrl
        // channel handshake (peer IP) and streams to us.
    }

    func start() {
        let params = NWParameters.udp
        let conn = NWConnection(host: "0.0.0.0", port: NWEndpoint.Port(rawValue: port)!, using: params)
        listener = conn
        conn.start(queue: .global(qos: .userInteractive))
        receive(on: conn)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        lock.lock(); frames.removeAll(); frameChunkCount.removeAll(); lock.unlock()
    }

    private func receive(on conn: NWConnection) {
        conn.receiveMessage { [weak self] data, _, _, err in
            guard let self else { return }
            if let data, data.count >= 29 { self.handlePacket(data) }
            if err == nil { self.receive(on: conn) }
        }
    }

    // IDSP header (big-endian): magic(4) seq(4) ts(8) frameId(4) total(2) index(2) flags(1) size(4)
    private func handlePacket(_ pkt: Data) {
        func be32(_ o: Int) -> UInt32 {
            (UInt32(pkt[o]) << 24) | (UInt32(pkt[o+1]) << 16) | (UInt32(pkt[o+2]) << 8) | UInt32(pkt[o+3])
        }
        func be16(_ o: Int) -> UInt16 { (UInt16(pkt[o]) << 8) | UInt16(pkt[o+1]) }

        guard be32(0) == 0x49445350 else { return }         // "IDSP" (trust boundary)
        let frameId = be32(16)
        let total   = Int(be16(20))
        let index   = Int(be16(22))
        let flags   = pkt[24]
        let size    = Int(be32(25))
        guard size >= 0, pkt.count >= 29 + size, total > 0, index < total else { return }
        let isKey = (flags & 0x01) != 0
        let payload = pkt.subdata(in: 29..<(29 + size))

        lock.lock()
        frames[frameId, default: [:]][index] = payload
        frameChunkCount[frameId] = total
        let complete = frames[frameId]!.count == total
        var assembled: Data?
        if complete {
            var full = Data()
            for i in 0..<total { full.append(frames[frameId]![i] ?? Data()) }
            assembled = full
            frames[frameId] = nil
            frameChunkCount[frameId] = nil
        }
        // ponytail: drop stale partial frames if the map grows (late/lost packets). Simple cap.
        if frames.count > 8 { frames.removeAll(); frameChunkCount.removeAll() }
        lock.unlock()

        if let nal = assembled { onNAL(nal, isKey) }
    }
}
