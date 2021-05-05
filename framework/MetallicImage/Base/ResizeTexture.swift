//
//  ResizeTexture.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/14/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

@available(iOS 11.0, tvOS 11.0, *)
public class ResizeTexture: BasicMPSFilter {
    private var scaleTransform = MPSScaleTransform()

    public var targetWidth: Int = 0

    public var targetHeight: Int = 0

    public var keepAspectRatio: Bool = false

    public init() {
        super.init()
        internalImageKernel = MPSImageBilinearScale(device: renderTarget.context.device)
    }

    public override func newTexture(_ texture: Texture) {
        _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }

        let widthRatio = Double(targetWidth) / Double(texture.width)
        let heightRatio = Double(targetHeight) / Double(texture.height)
        let targetTextureWidth: Int
        let targetTextureHeight: Int
        let needsFlip = texture.orientation.rotationNeeded(for: .portrait).flipsDimensions()
        if keepAspectRatio {
            let minRatio = min(widthRatio, heightRatio)
            targetTextureWidth = needsFlip ? Int(minRatio * Double(texture.height)) : Int(minRatio * Double(texture.width))
            targetTextureHeight = needsFlip ? Int(minRatio * Double(texture.width)) : Int(minRatio * Double(texture.height))
        } else {
            targetTextureWidth = needsFlip ? targetHeight : targetWidth
            targetTextureHeight = needsFlip ? targetWidth : targetHeight
        }
        let outputTexture = Texture(orientation: texture.orientation,
                                    width: targetTextureWidth,
                                    height: targetTextureHeight,
                                    timingType: texture.timingType,
                                    pixelFormat: texture.pixelFormat,
                                    colorSpace: texture.colorSpace)
        guard let commandBuffer = renderTarget.context.commandQueue.makeCommandBuffer() else {
            print("Warning: \(operationName) Failed to create command buffer")
            return
        }
        commandBuffer.label = operationName
        if useMetalPerformanceShaders {
            renderWithShader(commandBuffer: commandBuffer, sourceTexture: texture.texture, destinationTexture: outputTexture.texture)
        } else {
            commandBuffer.render(from: texture, to: outputTexture, targetState: renderTarget)
        }
        commandBuffer.commit()

        textureInputSemaphore.signal()
        commandBuffer.waitUntilCompleted()
        previousTexture = outputTexture
        updateTargets(with: outputTexture)
        _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
    }

    public override func renderWithShader(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        withUnsafePointer(to: &scaleTransform) { scale in
            (internalImageKernel as? MPSImageBilinearScale)?.scaleTransform = scale
            internalImageKernel?.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destinationTexture)
        }
    }
}
