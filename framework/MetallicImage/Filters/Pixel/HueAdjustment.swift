//
//  HueAdjustment.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/16/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import Foundation

public class HueAdjustment: BasicFilter {
    @objc
    public var hue: Float = 0.0 {
        didSet {
            renderTarget.setFragmentBufferValue(hue, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "hueFragment")
        ({ hue = 0.0 })()
    }
}
