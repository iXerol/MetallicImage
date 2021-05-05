//
//  SatuationAdjustment.swift
//  MetallicImage
//
//  Created by Xerol Wong on 4/22/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import Foundation

public class SaturationAdjustment: BasicFilter {
    @objc
    public var saturation: Float = 1.0 {
        didSet {
            renderTarget.setFragmentBufferValue(saturation, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "saturationFragment")
        ({ saturation = 1.0 })()
    }
}
