//
//  LanzosScale.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/14/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

public class LanczosScale: BasicMPSFilter {
    private var scaleTransform = MPSScaleTransform(scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)

    @objc
    public var scaleX: Float {
        get {
            return Float(scaleTransform.scaleX)
        }
        set {
            scaleTransform.scaleX = Double(newValue)
        }
    }

    @objc
    public var scaleY: Float {
        get {
            return Float(scaleTransform.scaleY)
        }
        set {
            scaleTransform.scaleY = Double(newValue)
        }
    }

    @objc
    public var translateX: Float {
        get {
            return Float(scaleTransform.translateX)
        }
        set {
            scaleTransform.translateX = Double(newValue)
        }
    }

    @objc
    public var translateY: Float {
        get {
            return Float(scaleTransform.translateY)
        }
        set {
            scaleTransform.translateY = Double(newValue)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        if useMetalPerformanceShaders {
            internalImageKernel = MPSImageLanczosScale(device: renderTarget.context.device)
        } else {
            fatalError("Lanzos Scale isno't available on pre-MPS OS versions")
        }
    }

    public override func renderWithShader(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        if useMetalPerformanceShaders {
            withUnsafePointer(to: &scaleTransform) { scale in
                (internalImageKernel as? MPSImageLanczosScale)?.scaleTransform = scale
                internalImageKernel?.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destinationTexture)
            }
        }
    }
}
