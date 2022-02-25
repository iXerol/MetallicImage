//
//  MovieOutput.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/12/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import AVFoundation
import Dispatch

public class MovieOutput: ImageConsumer {
    let assetWriter: AVAssetWriter
    let assetWriterVideoInput: AVAssetWriterInput

    let assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor
    let width: Int
    let height: Int
    public let orientation: ImageOrientation
    private var isRecording = false
    private var videoEncodingIsFinished = false
    private var startTime: CMTime?
    private var previousFrameTime = CMTime.negativeInfinity
    var renderTarget: RenderTargetState

    var transform: CGAffineTransform {
        get {
            return assetWriterVideoInput.transform
        }
        set {
            assetWriterVideoInput.transform = newValue
        }
    }

    let movieWritingQueue = DispatchQueue(label: "com.MetallicImage.imageWritingQueue")

    public init(context: MIContext = .default,
                URL: URL,
                width: Int,
                height: Int,
                fileType: AVFileType = .mov,
                orientation: ImageOrientation = .portrait,
                videoCodec: AVVideoCodecType) throws {
        self.width = width
        self.height = height
        self.orientation = orientation
        assetWriter = try AVAssetWriter(url: URL, fileType: fileType)
        assetWriter.movieFragmentInterval = CMTime(seconds: 1.0, preferredTimescale: 1000)

        let videoSettings: [String: Any] =
            [AVVideoWidthKey: NSNumber(value: width),
             AVVideoHeightKey: NSNumber(value: height),
             AVVideoCodecKey: videoCodec]

        assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true

        let sourcePixelBufferAttributesDictionary: [String: Any] =
            [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: UInt32(kCVPixelFormatType_32BGRA)),
             kCVPixelBufferWidthKey as String: NSNumber(value: width),
             kCVPixelBufferHeightKey as String: NSNumber(value: height)]

        assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        assetWriter.add(assetWriterVideoInput)

        renderTarget = RenderTargetState(context: context)
    }

    public func startRecording(transform: CGAffineTransform? = nil) {
        if let transform = transform {
            assetWriterVideoInput.transform = transform
        }
        startTime = nil
        isRecording = assetWriter.startWriting()
    }

    public func finishRecording(_ completion: (() -> Void)? = nil) {
        isRecording = false

        switch assetWriter.status {
        case .completed, .cancelled, .unknown:

            DispatchQueue.global().async {
                completion?()
            }
            return
        case .writing:
            if !videoEncodingIsFinished {
                videoEncodingIsFinished = true
                assetWriterVideoInput.markAsFinished()
            }
        default:
            break
        }

        assetWriter.finishWriting(completionHandler: completion ?? {})
    }

    public func newTexture(_ texture: Texture) {
        guard isRecording,
            let frameTime = texture.timingType.cmTime,
            frameTime != previousFrameTime else {
            return
        }

        if startTime == nil {
            if assetWriter.status != .writing {
                assetWriter.startWriting()
            }

            assetWriter.startSession(atSourceTime: frameTime)
            startTime = frameTime
        }

        movieWritingQueue.async {
            guard self.assetWriterVideoInput.isReadyForMoreMediaData else {
                debugPrint("Had to drop a frame at time \(frameTime)")
                return
            }

            var pixelBufferFromPool: CVPixelBuffer?

            let pixelBufferStatus = CVPixelBufferPoolCreatePixelBuffer(nil, self.assetWriterPixelBufferInput.pixelBufferPool!, &pixelBufferFromPool)
            guard let pixelBuffer = pixelBufferFromPool, pixelBufferStatus == kCVReturnSuccess else { return }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            self.render(texture: texture, into: pixelBuffer)

            if !self.assetWriterPixelBufferInput.append(pixelBuffer, withPresentationTime: frameTime) {
                print("Failed to append pixel buffer at time: \(frameTime)")
            }

            CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        }
    }

    func render(texture: Texture, into pixelBuffer: CVPixelBuffer) {
        guard let pixelBufferBytes = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Could not get buffer bytes")
            return
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        let commandBuffer = renderTarget.context.commandQueue.makeCommandBuffer()
        let outputTexture = Texture(device: renderTarget.context.device, orientation: orientation, width: width, height: height, timingType: texture.timingType, colorSpace: texture.colorSpace)
        commandBuffer?.render(from: texture, to: outputTexture, targetState: renderTarget)
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()

        let region = MTLRegionMake2D(0, 0, outputTexture().width, outputTexture().height)

        outputTexture().getBytes(pixelBufferBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
    }
}
