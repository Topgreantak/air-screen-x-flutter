import UIKit

// Maps UITouch coords → normalized 0..1 over the content viewport (excludes letterbox bars),
// then hands an InputPacket to the transmitter. README section 6.8. Not built here.

final class TouchHandler {
    private let transmitter: InputTransmitter
    var contentViewport: CGRect = .zero    // set by the renderer's layout

    init(transmitter: InputTransmitter) { self.transmitter = transmitter }

    func handle(_ touches: Set<UITouch>, type: InputPacket.EventType, in view: UIView) {
        let points: [TouchPoint] = touches.compactMap { t in
            let loc = t.location(in: view)
            guard contentViewport.contains(loc) else { return nil } // ignore bar taps
            let nx = (loc.x - contentViewport.minX) / contentViewport.width
            let ny = (loc.y - contentViewport.minY) / contentViewport.height
            return TouchPoint(id: UInt8(t.hash & 0xFF), normX: Float(nx), normY: Float(ny))
        }
        guard !points.isEmpty else { return }
        transmitter.send(InputPacket(
            type: type, touches: points,
            timestampUs: UInt64(Date().timeIntervalSince1970 * 1_000_000)))
    }
}
