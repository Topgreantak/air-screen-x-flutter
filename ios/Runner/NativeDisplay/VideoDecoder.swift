import VideoToolbox
import CoreMedia
import Foundation

// VideoToolbox H.264 decoder. Session is created once SPS/PPS arrive; invalidate() releases it.
// Memory rule: invalidate on stop and in deinit. NOTE: not built here (needs macOS/Xcode).

final class VideoDecoder {
    typealias FrameCallback = (CVPixelBuffer, CMTime) -> Void

    private var session: VTDecompressionSession?
    private var formatDescription: CMVideoFormatDescription?
    private var frameCallback: FrameCallback?
    private var spsData: Data?
    private var ppsData: Data?

    func configure(callback: @escaping FrameCallback) { frameCallback = callback }

    // Feed a single NAL unit (Annex-B start code already stripped by the reassembler).
    func decodeNAL(_ data: Data) {
        guard !data.isEmpty else { return }
        let nalType = data[data.startIndex] & 0x1F
        switch nalType {
        case 7: spsData = data; tryCreateSession()
        case 8: ppsData = data; tryCreateSession()
        case 1, 5: decodeSlice(data)
        default: break
        }
    }

    private func tryCreateSession() {
        guard session == nil, let sps = spsData, let pps = ppsData else { return }
        var desc: CMVideoFormatDescription?
        let spsBytes = [UInt8](sps), ppsBytes = [UInt8](pps)
        let status = spsBytes.withUnsafeBufferPointer { sp in
            ppsBytes.withUnsafeBufferPointer { pp -> OSStatus in
                let ptrs: [UnsafePointer<UInt8>?] = [sp.baseAddress, pp.baseAddress]
                let sizes: [Int] = [sp.count, pp.count]
                return ptrs.withUnsafeBufferPointer { pb in
                    CMVideoFormatDescriptionCreateFromH264ParameterSets(
                        allocator: nil, parameterSetCount: 2,
                        parameterSetPointers: pb.baseAddress!, parameterSetSizes: sizes,
                        nalUnitHeaderLength: 4, formatDescriptionOut: &desc)
                }
            }
        }
        guard status == noErr, let fmt = desc else { return }
        formatDescription = fmt

        let attrs: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            kCVPixelBufferMetalCompatibilityKey: true,
        ]
        var cb = VTDecompressionOutputCallbackRecord(
            decompressionOutputCallback: { refCon, _, status, _, imageBuffer, pts, _ in
                guard status == noErr, let pb = imageBuffer, let refCon else { return }
                let me = Unmanaged<VideoDecoder>.fromOpaque(refCon).takeUnretainedValue()
                me.frameCallback?(pb, pts)
            },
            decompressionOutputRefCon: Unmanaged.passUnretained(self).toOpaque())
        VTDecompressionSessionCreate(allocator: nil, formatDescription: fmt,
                                     decoderSpecification: nil, imageBufferAttributes: attrs as CFDictionary,
                                     outputCallback: &cb, decompressionSessionOut: &session)
    }

    private func decodeSlice(_ data: Data) {
        guard let session, let fmt = formatDescription else { return }
        var length = UInt32(data.count).bigEndian            // AVCC 4-byte length prefix
        var full = Data(bytes: &length, count: 4); full.append(data)

        var block: CMBlockBuffer?
        full.withUnsafeMutableBytes { ptr in
            CMBlockBufferCreateWithMemoryBlock(
                allocator: nil, memoryBlock: ptr.baseAddress, blockLength: full.count,
                blockAllocator: kCFAllocatorNull, customBlockSource: nil,
                offsetToData: 0, dataLength: full.count, flags: 0, blockBufferOut: &block)
        }
        guard let block else { return }
        var sample: CMSampleBuffer?
        var sampleSize = full.count
        CMSampleBufferCreate(allocator: nil, dataBuffer: block, dataReady: true,
                             makeDataReadyCallback: nil, refcon: nil, formatDescription: fmt,
                             sampleCount: 1, sampleTimingEntryCount: 0, sampleTimingArray: nil,
                             sampleSizeEntryCount: 1, sampleSizeArray: &sampleSize, sampleBufferOut: &sample)
        guard let sample else { return }
        VTDecompressionSessionDecodeFrame(session, sampleBuffer: sample,
                                          flags: [._EnableAsynchronousDecompression],
                                          infoFlagsOut: nil, outputHandler: nil)
    }

    func invalidate() {
        if let session { VTDecompressionSessionInvalidate(session) }
        session = nil; formatDescription = nil; spsData = nil; ppsData = nil; frameCallback = nil
    }

    deinit { invalidate() }
}
