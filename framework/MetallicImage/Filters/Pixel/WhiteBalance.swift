//
//  WhiteBalance.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/15/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import Foundation

public class WhiteBalance: BasicFilter {
    private var fragmentBytes: [Float] {
        return [tint / 100.0, temperature < 5000.0 ? 0.0004 * (temperature - 5000.0) : 0.00006 * (temperature - 5000.0)]
    }

    @objc
    public var temperature: Float = 5000.0 {
        didSet {
            renderTarget.setFragmentBufferValue(fragmentBytes, at: 0)
        }
    }

    @objc
    public var tint: Float = 0.0 {
        didSet {
            renderTarget.setFragmentBufferValue(fragmentBytes, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "whiteBalanceFragmentShader")
        renderTarget.setFragmentBufferValue(fragmentBytes, at: 0)
    }
}
