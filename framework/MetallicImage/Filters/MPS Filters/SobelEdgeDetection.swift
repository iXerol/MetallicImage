//
//  SobelEdgeDetection.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/15/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

public class SobelEdgeDetection: BasicMPSFilter {
    private var colorTransform: [Float] = [0.33, 0.33, 0.33]

    @objc
    public var x: Float {
        get {
            return colorTransform[0]
        }
        set {
            colorTransform[0] = newValue
        }
    }

    @objc
    public var y: Float {
        get {
            return colorTransform[1]
        }
        set {
            colorTransform[1] = newValue
        }
    }

    /// Useless in 2D texture
    @objc
    public var z: Float {
        get {
            return colorTransform[2]
        }
        set {
            colorTransform[2] = newValue
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        if !useMetalPerformanceShaders {
            fatalError("Sobel Edge Detection isno't available on pre-MPS OS versions")
        }
    }

    public override func renderWithShader(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        if useMetalPerformanceShaders {
            internalImageKernel = MPSImageSobel(device: renderTarget.context.device, linearGrayColorTransform: colorTransform)
            internalImageKernel?.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destinationTexture)
        }
    }
}
