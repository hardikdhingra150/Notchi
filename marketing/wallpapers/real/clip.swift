// Turns real footage into Notchi wallpapers. No ffmpeg needed: AVFoundation only.
//
//   swift clip.swift info   <file-or-url>
//   swift clip.swift frames <file-or-url> <every-seconds> <out-folder> [from] [to]
//   swift clip.swift loop   <file-or-url> <start> <length> <out-base> [--fade 1.5] [--speed 1] [--zoom 1] [--bitrate 4500000]
//
// `loop` writes <out-base>.mp4 (1080p), <out-base>-preview.mp4 (640x360) and <out-base>.jpg.
// The loop is seamless: the footage that follows the clip is faded out over the clip's
// first seconds, so the last frame flows into the first. Sound is dropped.
// A remote .mp4 is read with range requests, so a 2 GB source isn't downloaded.
import AVFoundation
import AppKit
import CoreImage

func die(_ s: String) -> Never { FileHandle.standardError.write(Data((s + "\n").utf8)); exit(1) }
let args = Array(CommandLine.arguments.dropFirst())
guard args.count >= 2 else { die("usage: clip.swift info|frames|loop <file-or-url> …") }
func source(_ s: String) -> URL { s.hasPrefix("http") ? URL(string: s)! : URL(fileURLWithPath: s) }
func flag(_ name: String, _ fallback: Double) -> Double {
    guard let i = args.firstIndex(of: name), i + 1 < args.count, let v = Double(args[i + 1]) else { return fallback }
    return v
}
func t(_ s: Double) -> CMTime { CMTime(seconds: s, preferredTimescale: 600) }
func jpeg(_ cg: CGImage, _ url: URL, quality: Double = 0.8) {
    let rep = NSBitmapImageRep(cgImage: cg)
    try? rep.representation(using: .jpeg, properties: [.compressionFactor: quality])?.write(to: url)
}

let asset = AVURLAsset(url: source(args[1]))
let sem = DispatchSemaphore(value: 0)

Task {
    do {
        let duration = try await asset.load(.duration).seconds
        guard let video = try await asset.loadTracks(withMediaType: .video).first else { die("no video track") }
        let size = try await video.load(.naturalSize)
        let fps = try await video.load(.nominalFrameRate)

        switch args[0] {
        case "info":
            print(String(format: "%.1f s, %.0fx%.0f, %.2f fps", duration, size.width, size.height, fps))

        case "frames":
            guard args.count >= 4, let step = Double(args[2]) else { die("usage: frames <src> <every-seconds> <out-folder> [from] [to]") }
            let out = URL(fileURLWithPath: args[3])
            try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
            let from = args.count > 4 ? Double(args[4]) ?? 0 : 0
            let to = args.count > 5 ? Double(args[5]) ?? duration : duration
            let gen = AVAssetImageGenerator(asset: asset)
            gen.maximumSize = CGSize(width: 480, height: 270)
            gen.requestedTimeToleranceBefore = t(2); gen.requestedTimeToleranceAfter = t(2)
            var s = from
            while s < to {
                if let (cg, _) = try? await gen.image(at: t(s)) {
                    jpeg(cg, out.appendingPathComponent(String(format: "%05d.jpg", Int(s))), quality: 0.6)
                }
                s += step
            }
            print("frames in \(out.path)")

        case "loop":
            guard args.count >= 5, let start = Double(args[2]), let length = Double(args[3]) else { die("usage: loop <src> <start> <length> <out-base>") }
            let base = args[4]
            let fade = flag("--fade", 1.5), speed = flag("--speed", 1)
            // source seconds needed: the clip, plus `fade` more that is blended over its start
            let srcLen = length * speed, srcFade = fade * speed
            guard start + srcLen + srcFade <= duration else { die("clip runs past the end of the source") }

            let comp = AVMutableComposition()
            let a = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            let b = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
            try a.insertTimeRange(CMTimeRange(start: t(start), duration: t(srcLen)), of: video, at: .zero)
            try b.insertTimeRange(CMTimeRange(start: t(start + srcLen), duration: t(srcFade)), of: video, at: .zero)
            if speed != 1 {
                a.scaleTimeRange(CMTimeRange(start: .zero, duration: t(srcLen)), toDuration: t(length))
                b.scaleTimeRange(CMTimeRange(start: .zero, duration: t(srcFade)), toDuration: t(fade))
            }

            func render(_ w: Int, _ h: Int, bitrate: Int, to url: URL) async throws {
                // aspect-fill the source into w x h
                // --zoom crops a little off every edge (letterbox bars, window frames)
                let scale = max(CGFloat(w) / size.width, CGFloat(h) / size.height) * CGFloat(flag("--zoom", 1))
                let fit = CGAffineTransform(scaleX: scale, y: scale)
                    .concatenating(CGAffineTransform(translationX: (CGFloat(w) - size.width * scale) / 2, y: (CGFloat(h) - size.height * scale) / 2))
                let la = AVMutableVideoCompositionLayerInstruction(assetTrack: a)
                la.setTransform(fit, at: .zero)
                let lb = AVMutableVideoCompositionLayerInstruction(assetTrack: b)
                lb.setTransform(fit, at: .zero)
                lb.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: CMTimeRange(start: .zero, duration: t(fade)))
                let first = AVMutableVideoCompositionInstruction()
                first.timeRange = CMTimeRange(start: .zero, duration: t(fade))
                first.layerInstructions = [lb, la]           // the tail on top, fading away
                let rest = AVMutableVideoCompositionInstruction()
                rest.timeRange = CMTimeRange(start: t(fade), duration: t(length - fade))
                rest.layerInstructions = [la]
                let vc = AVMutableVideoComposition()
                vc.instructions = [first, rest]
                vc.renderSize = CGSize(width: w, height: h)
                vc.frameDuration = CMTime(value: 1, timescale: 30)

                try? FileManager.default.removeItem(at: url)
                let reader = try AVAssetReader(asset: comp)
                let out = AVAssetReaderVideoCompositionOutput(videoTracks: [a, b], videoSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange])
                out.videoComposition = vc
                reader.add(out)
                reader.timeRange = CMTimeRange(start: .zero, duration: t(length))
                let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
                writer.shouldOptimizeForNetworkUse = true
                let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: w, AVVideoHeightKey: h,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: bitrate, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                        AVVideoMaxKeyFrameIntervalKey: 60, AVVideoAllowFrameReorderingKey: true,
                    ] as [String: Any],
                ])
                input.expectsMediaDataInRealTime = false
                writer.add(input)
                guard reader.startReading() else { die("can't read: \(reader.error?.localizedDescription ?? "?")") }
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                while let buf = out.copyNextSampleBuffer() {
                    while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 5_000_000) }
                    input.append(buf)
                }
                input.markAsFinished()
                await writer.finishWriting()
                if writer.status != .completed { die("write failed: \(writer.error?.localizedDescription ?? "?")") }
            }

            try await render(1920, 1080, bitrate: Int(flag("--bitrate", 4_500_000)), to: URL(fileURLWithPath: base + ".mp4"))
            try await render(640, 360, bitrate: 420_000, to: URL(fileURLWithPath: base + "-preview.mp4"))
            let gen = AVAssetImageGenerator(asset: AVURLAsset(url: URL(fileURLWithPath: base + ".mp4")))
            gen.maximumSize = CGSize(width: 1280, height: 720)
            let (cg, _) = try await gen.image(at: t(length / 2))
            jpeg(cg, URL(fileURLWithPath: base + ".jpg"), quality: 0.78)
            let mb = { (p: String) in Double((try? FileManager.default.attributesOfItem(atPath: p)[.size] as? Int) ?? 0) / 1_048_576 }
            print(String(format: "%@: %.0f s loop, %.1f MB + %.1f MB preview", (base as NSString).lastPathComponent, length, mb(base + ".mp4"), mb(base + "-preview.mp4")))

        default:
            die("unknown command \(args[0])")
        }
    } catch { die("\(error)") }
    sem.signal()
}
sem.wait()
