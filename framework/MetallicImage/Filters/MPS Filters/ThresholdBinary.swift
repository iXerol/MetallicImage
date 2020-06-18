//
//  ThresholdBinary.swift
//  MetallicImage
//
//  Created by Xerol Wong on 2020/05/25.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalPerformanceShaders

public class ThresholdBinary: BasicMPSFilter {
    @objc
    public var thresholdValue: Float = 0.5 {
        didSet {
            internalImageKernel = MPSImageThresholdBinary(device: renderTarget.context.device, thresholdValue: thresholdValue, maximumValue: maximumValue, linearGrayColorTransform: nil)
        }
    }

    @objc
    public var maximumValue: Float = 1 {
        didSet {
            internalImageKernel = MPSImageThresholdBinary(device: renderTarget.context.device, thresholdValue: thresholdValue, maximumValue: maximumValue, linearGrayColorTransform: nil)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        if useMetalPerformanceShaders {
            internalImageKernel = MPSImageThresholdBinary(device: context.device, thresholdValue: thresholdValue, maximumValue: maximumValue, linearGrayColorTransform: nil)
        } else {
            fatalError("Threshold Binary isno't available on pre-MPS OS versions")
        }
    }
}
