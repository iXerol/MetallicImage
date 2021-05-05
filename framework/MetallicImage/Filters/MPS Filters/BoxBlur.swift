//
//  BoxBlur.swift
//  MetallicImage
//
//  Created by Xerol Wong on 4/15/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

public class BoxBlur: BasicMPSFilter {
    @objc
    public var blurDiameter: Float = 2.0 {
        didSet {
            if useMetalPerformanceShaders {
                let kernelSize = roundToOdd(blurDiameter) // MPS box blur kernels need to be odd
                internalImageKernel = MPSImageBox(device: renderTarget.context.device, kernelWidth: kernelSize, kernelHeight: kernelSize)
            } else {
                fatalError("Box Blur isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        ({ blurDiameter = 2.0 })()
    }
}
