//
//  BrightnessAdjustment.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/13/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//
import Foundation

public class BrightnessAdjustment: BasicFilter {
    @objc
    public var brightness: Float = 0.0 {
        didSet {
            renderTarget.setFragmentBufferValue(brightness, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "brightnessFragment")
        ({ brightness = 0.0 })()
    }
}
