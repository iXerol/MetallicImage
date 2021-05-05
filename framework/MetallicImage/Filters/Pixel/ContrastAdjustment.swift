//
//  ContrastAdjustment.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/13/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import Foundation

public class ContrastAdjustment: BasicFilter {
    @objc
    public var contrast: Float = 1.0 {
        didSet {
            renderTarget.setFragmentBufferValue(contrast, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "saturationFragment")
        ({ contrast = 1.0 })()
    }
}
