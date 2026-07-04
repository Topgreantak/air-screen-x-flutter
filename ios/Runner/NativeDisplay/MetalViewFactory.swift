import Flutter
import UIKit
import MetalKit

// Platform-view factory for 'idisplay/metal-view'. Builds an MTKView driven by MetalRenderer,
// binds it to the session's decoder output, and forwards touches. R4: pauses on idle. Not built here.

final class MetalViewFactory: NSObject, FlutterPlatformViewFactory {
    private let session: DisplaySession
    init(session: DisplaySession) { self.session = session }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)
        -> FlutterPlatformView {
        return MetalPlatformView(frame: frame, session: session)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
}

final class MetalPlatformView: NSObject, FlutterPlatformView {
    private let container = UIView()
    private let mtkView: MTKView
    private let renderer: MetalRenderer?
    private let touch: TouchHandler?
    private let session: DisplaySession

    init(frame: CGRect, session: DisplaySession) {
        self.session = session
        mtkView = MTKView(frame: frame)
        mtkView.framebufferOnly = true
        mtkView.colorPixelFormat = .bgra8Unorm
        renderer = MetalRenderer(mtkView: mtkView)
        touch = session.input.map { TouchHandler(transmitter: $0) }
        super.init()

        container.addSubview(mtkView)
        mtkView.frame = container.bounds
        mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // decoded frame → renderer + keep letterbox layout in sync with the stream size (R aspect).
        session.onFrame = { [weak self] pb in
            guard let self, let r = self.renderer else { return }
            r.updateLayout(streamSize: self.session.streamSize, screenSize: self.mtkView.drawableSize)
            r.updateFrame(pb)
            self.touch?.contentViewport = self.viewportForTouch()
            self.mtkView.isPaused = false                 // R4: wake on frame
        }
        // R4 idle-stop: pause redraws when the host reports STREAM_IDLE.
        let prevStatus = session.onStatus
        session.onStatus = { [weak self] s in
            if let e = s["event"] as? String {
                if e == "idle" { self?.mtkView.isPaused = true }
                if e == "resume" { self?.mtkView.isPaused = false }
            }
            prevStatus?(s)
        }
    }

    private func viewportForTouch() -> CGRect {
        // Mirror the renderer's letterbox math for touch mapping.
        let s = session.streamSize, screen = mtkView.bounds.size
        guard s.height > 0, screen.height > 0 else { return mtkView.bounds }
        let sa = s.width / s.height, ca = screen.width / screen.height
        if sa > ca {
            let h = screen.width / sa
            return CGRect(x: 0, y: (screen.height - h) / 2, width: screen.width, height: h)
        } else {
            let w = screen.height * sa
            return CGRect(x: (screen.width - w) / 2, y: 0, width: w, height: screen.height)
        }
    }

    func view() -> UIView { container }
}
