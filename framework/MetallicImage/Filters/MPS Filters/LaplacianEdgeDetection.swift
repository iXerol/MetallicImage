//
//  LaplacianEdgeDetection.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/15/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

@available(iOS 10.0, tvOS 10.0, *)
public class LaplacianEdgeDetection: BasicMPSFilter {
    @objc
    public var bias: Float = 0.0 {
        didSet {
            if useMetalPerformanceShaders {
                (internalImageKernel as? MPSImageLaplacian)?.bias = bias
            } else {
                fatalError("Laplacian Edge Detection isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        if useMetalPerformanceShaders {
            internalImageKernel = MPSImageLaplacian(device: context.device)
        }
    }
}
