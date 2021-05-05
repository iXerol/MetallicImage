//
//  CGSize+Flip.swift
//  MetallicImage
//
//  Created by Xerol Wong on 5/10/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import CoreGraphics

extension CGSize {
    func flipped() -> CGSize {
        return CGSize(width: height, height: width)
    }
}
