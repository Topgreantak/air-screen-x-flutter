import Metal
import MetalKit
import CoreVideo

// Renders decoded CVPixelBuffers, preserving aspect ratio via a centered viewport (letterbox/
// pillarbox — never stretch). R4 idle-stop: `paused` stops redraws to save power.
// NOTE: not built here (needs macOS/Xcode).

final class MetalRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private var textureCache: CVMetalTextureCache?

    private var pixelBuffer: CVPixelBuffer?
    private let lock = NSLock()

    private var contentViewport = CGRect.zero
    private var screenSize = CGSize.zero

    var paused = false { didSet { /* driven by MTKView.isPaused in the factory */ } }

    init?(mtkView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else { return nil }
        self.device = device
        self.commandQueue = queue

        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "vertexShader")
        desc.fragmentFunction = library.makeFunction(name: "fragmentShader_ycbcr")
        desc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        guard let ps = try? device.makeRenderPipelineState(descriptor: desc) else { return nil }
        self.pipeline = ps
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        mtkView.device = device
        super.init()
        mtkView.delegate = self
    }

    func updateFrame(_ pb: CVPixelBuffer) {
        lock.lock(); pixelBuffer = pb; lock.unlock()
    }

    func updateLayout(streamSize: CGSize, screenSize: CGSize) {
        self.screenSize = screenSize
        guard streamSize.height > 0, screenSize.height > 0 else { return }
        let sa = streamSize.width / streamSize.height
        let ca = screenSize.width / screenSize.height
        if sa > ca {
            let h = screenSize.width / sa
            contentViewport = CGRect(x: 0, y: (screenSize.height - h) / 2, width: screenSize.width, height: h)
        } else {
            let w = screenSize.height * sa
            contentViewport = CGRect(x: (screenSize.width - w) / 2, y: 0, width: w, height: screenSize.height)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { screenSize = size }

    func draw(in view: MTKView) {
        lock.lock(); let pb = pixelBuffer; lock.unlock()
        guard let pb, let cache = textureCache,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let cmd = commandQueue.makeCommandBuffer() else { return }

        rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1) // black bars
        rpd.colorAttachments[0].loadAction = .clear

        let w = CVPixelBufferGetWidth(pb), h = CVPixelBufferGetHeight(pb)
        var cvTex: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(nil, cache, pb, nil, .bgra8Unorm, w, h, 0, &cvTex)
        guard let cvTex, let tex = CVMetalTextureGetTexture(cvTex),
              let enc = cmd.makeRenderCommandEncoder(descriptor: rpd) else { return }

        enc.setRenderPipelineState(pipeline)
        let vp = contentViewport == .zero ? CGRect(origin: .zero, size: screenSize) : contentViewport
        enc.setViewport(MTLViewport(originX: Double(vp.minX), originY: Double(vp.minY),
                                    width: Double(vp.width), height: Double(vp.height), znear: 0, zfar: 1))
        enc.setFragmentTexture(tex, index: 0)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
        cmd.present(drawable)
        cmd.commit()
        CVMetalTextureCacheFlush(cache, 0)   // release cached textures each frame
    }
}
