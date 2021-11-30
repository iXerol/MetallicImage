//
//  Camera.swift
//  MetallicImage
//
//  Created by Xerol Wong on 4/28/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

#if !os(tvOS)
import AVFoundation
import Foundation
import Metal

@available(iOS 9.0, macOS 10.13, macCatalyst 14.0, *)
public class Camera: NSObject, ImageSource {
    public enum CameraError: Error {
        case noCameraDevice
        case sessionConfigurationFailed
        case cameraNotAuthorized
    }

    public let targets = TargetContainer()
    public let context: MIContext
    public var orientation: ImageOrientation

    public let captureSession: AVCaptureSession
    public let inputCamera: AVCaptureDevice!
    let videoInput: AVCaptureDeviceInput!
    let videoOutput: AVCaptureVideoDataOutput!
    var videoTextureCache: CVMetalTextureCache?
    var previousTexture: Texture?

    let frameRenderingSemaphore = DispatchSemaphore(value: 1)
    let cameraCaptureQueue = DispatchQueue(label: "com.MetallicImage.cameraCaptureQueue")
    let imageProcessingQueue = DispatchQueue(label: "com.MetallicImage.imageProcessingQueue")

    public var runBenchmark: Bool = false

    var colorSpace: CGColorSpace? {
#if targetEnvironment(macCatalyst)
        inputCamera.activeColorSpace.cgColorSoace
#else
        if #available(iOS 10.0, macOS 10.15, *) {
            return inputCamera.activeColorSpace.cgColorSoace
        } else {
            return nil
        }
#endif
    }

    public init(sessionPreset: AVCaptureSession.Preset = .medium,
                cameraDevice: AVCaptureDevice? = AVCaptureDevice.default(for: .video),
                orientation: ImageOrientation? = nil,
                context: MIContext = .default) throws {
        self.context = context

        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        defer {
            captureSession.commitConfiguration()
        }

        guard let device = cameraDevice else {
            videoInput = nil
            videoOutput = nil
            inputCamera = nil
            self.orientation = .landscapeLeft
            super.init()
            throw CameraError.noCameraDevice
        }

        if let orientation = orientation {
            self.orientation = orientation
        } else {
            switch device.position {
            case .back:
                self.orientation = .landscapeLeft
            case .front:
#if os(iOS)
                self.orientation = .landscapeRightMirrored
#else
                self.orientation = .portrait
#endif
            default:
                self.orientation = .landscapeLeft
            }
        }
        inputCamera = device
        do {
            videoInput = try AVCaptureDeviceInput(device: device)
        } catch {
            videoInput = nil
            videoOutput = nil
            super.init()
            throw CameraError.sessionConfigurationFailed
        }
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: Int32(kCVPixelFormatType_32BGRA))]

        super.init()

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        if captureSession.canSetSessionPreset(sessionPreset) {
            captureSession.sessionPreset = sessionPreset
        }

        videoOutput.alwaysDiscardsLateVideoFrames = false
        videoOutput.setSampleBufferDelegate(self, queue: cameraCaptureQueue)
        let status = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, context.device, nil, &videoTextureCache)
        assert(status == kCVReturnSuccess, "Failed to create Metal texture cache")
    }

    deinit {
        stopCapture()
        videoOutput?.setSampleBufferDelegate(nil, queue: nil)
    }

    public func startCapture() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    public func stopCapture() {
        if captureSession.isRunning {
            _ = frameRenderingSemaphore.wait(timeout: DispatchTime.distantFuture)

            captureSession.stopRunning()
            frameRenderingSemaphore.signal()
        }
    }

    public func transmitPreviousImage(to target: ImageConsumer, completion: ((Bool) -> Void)? = nil) {
        guard frameRenderingSemaphore.wait(timeout: DispatchTime.now()) == DispatchTimeoutResult.success else {
            completion?(false)
            return
        }
        if let texture = previousTexture {
            target.newTexture(texture)
            completion?(true)
        } else {
            completion?(false)
        }
        frameRenderingSemaphore.signal()
    }
}

@available(iOS 9.0, tvOS 9.0, macOS 10.13, macCatalyst 14.0, *)
extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard frameRenderingSemaphore.wait(timeout: .now()) == DispatchTimeoutResult.success else { return }

        let startTime = CFAbsoluteTimeGetCurrent()
        let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        imageProcessingQueue.async {
            CVPixelBufferUnlockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

            var textureRef: CVMetalTexture?
            let status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .bgra8Unorm, bufferWidth, bufferHeight, 0, &textureRef)
            assert(status == kCVReturnSuccess, "Failed to create Metal texture from image")
            if let image = textureRef, let metalTexture = CVMetalTextureGetTexture(image) {
                self.previousTexture = Texture(texture: metalTexture,
                                               orientation: self.orientation,
                                               timingType: .videoFrame(time: currentTime),
                                               colorSpace: self.colorSpace)
                self.updateTargets(with: self.previousTexture!)
            }

            if self.runBenchmark {
                let currentFrameTime = (CFAbsoluteTimeGetCurrent() - startTime)
                print("Current frame time : \(1000.0 * currentFrameTime) ms")
            }

            self.frameRenderingSemaphore.signal()
        }
    }
}

@available(iOS 10.0, macOS 10.15, macCatalyst 14.0, *)
extension AVCaptureColorSpace {
    var cgColorSoace: CGColorSpace? {
        switch self {
        case .sRGB:
            return .init(name: CGColorSpace.sRGB)
        case .P3_D65:
            return .init(name: CGColorSpace.dcip3)
        case .HLG_BT2020:
            return .init(name: CGColorSpace.itur_2020)
        @unknown default:
            return nil
        }
    }
}

#endif
