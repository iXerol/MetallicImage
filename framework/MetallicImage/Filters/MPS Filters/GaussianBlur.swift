//
//  GaussianBlur.swift
//  MetallicImage
//
//  Created by Xerol Wong on 4/19/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

public class GaussianBlur: BasicMPSFilter {
    @objc
    public var sigma: Float = 2.0 {
        didSet {
            if useMetalPerformanceShaders {
                internalImageKernel = MPSImageGaussianBlur(device: renderTarget.context.device, sigma: sigma)
            } else {
                fatalError("Gaussian Blur isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        ({ sigma = 2.0 })()
    }
}
