//
//  Sharpen.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/16/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import Foundation
public class Sharpen: BasicFilter {
    @objc
    public var sharpness: Float = 0.0 {
        didSet {
            renderTarget.setFragmentBufferValue(sharpness, at: 0)
        }
    }

    public init() {
        super.init(vertexFunctionName: "sharpenVertex", fragmentFunctionName: "sharpenFragment")
        ({ sharpness = 0.0 })()
    }

    public override func newTexture(_ texture: Texture) {
        renderTarget.extraVertexBytes = [Float(texture.width), Float(texture.height)]
        super.newTexture(texture)
    }
}
