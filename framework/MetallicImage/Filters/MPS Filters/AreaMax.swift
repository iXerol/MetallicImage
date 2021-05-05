//
//  AreaMax.swift
//  MetallicImage
//
//  Created by Xerol Wong on 4/24/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

public class AreaMax: BasicMPSFilter {
    @objc
    public var kernelRadius: Float = 2.0 {
        didSet {
            if useMetalPerformanceShaders {
                let kernelSize = roundToOdd(kernelRadius) // MPS area max kernels need to be odd
                internalImageKernel = MPSImageAreaMax(device: renderTarget.context.device, kernelWidth: kernelSize, kernelHeight: kernelSize)
            } else {
                fatalError("Area Max isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        ({ kernelRadius = 2.0 })()
    }
}
