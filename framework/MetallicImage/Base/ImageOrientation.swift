//
//  ImageOrientation.swift
//  MetallicImage
//
//  Created by Xerol Wong on 3/22/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif

public enum ImageOrientation {
    case portrait
    /*
     1 2
     3 4
     */
    case portraitUpsideDown
    /*
     4 3
     2 1
     */
    case landscapeLeft
    /*
     2 4
     1 3
     */
    case landscapeRight
    /*
     3 1
     4 2
     */

    case portraitMirrored
    /*
     2 1
     4 3
     */
    case portraitUpsideDownMirrored
    /*
     3 4
     1 2
     */
    case landscapeLeftMirrored
    /*
     1 3
     2 4
     */
    case landscapeRightMirrored
    /*
     4 2
     3 1
     */

    #if canImport(UIKit)
    public init(with orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .portrait
        case .down:
            self = .portraitUpsideDown
        case .left:
            self = .landscapeRight
        case .right:
            self = .landscapeLeft
        case .upMirrored:
            self = .portraitMirrored
        case .downMirrored:
            self = .portraitUpsideDownMirrored
        case .leftMirrored:
            self = .landscapeRightMirrored
        case .rightMirrored:
            self = .landscapeLeftMirrored
        @unknown default:
            fatalError("Unknown UIImage Orientation")
        }
    }
    #endif
}

// MARK: Rotation
public enum Rotation {
    case noRotation
    case rotateCounterclockwise
    case rotateClockwise
    case rotate180
    case flipHorizontally
    case flipVertically
    case rotateClockwiseAndFlipVertically
    case rotateClockwiseAndFlipHorizontally

    func flipsDimensions() -> Bool {
        switch self {
        case .noRotation, .rotate180, .flipHorizontally, .flipVertically: return false
        case .rotateCounterclockwise, .rotateClockwise, .rotateClockwiseAndFlipVertically, .rotateClockwiseAndFlipHorizontally: return true
        }
    }
}

extension ImageOrientation {
    func rotationNeeded(for targetOrientation: ImageOrientation) -> Rotation {
        switch (self, targetOrientation) {
        case (.portrait, .portrait), (.portraitUpsideDown, .portraitUpsideDown),
             (.landscapeLeft, .landscapeLeft), (.landscapeRight, .landscapeRight),
             (.portraitMirrored, .portraitMirrored), (.portraitUpsideDownMirrored, .portraitUpsideDownMirrored),
             (.landscapeLeftMirrored, .landscapeLeftMirrored), (.landscapeRightMirrored, .landscapeRightMirrored):
            return .noRotation
        case (.portrait, .portraitUpsideDown), (.portraitUpsideDown, .portrait),
             (.landscapeLeft, .landscapeRight), (.landscapeRight, .landscapeLeft),
             (.portraitMirrored, .portraitUpsideDownMirrored), (.portraitUpsideDownMirrored, .portraitMirrored),
             (.landscapeRightMirrored, .landscapeLeftMirrored), (.landscapeLeftMirrored, .landscapeRightMirrored):
            return .rotate180
        case (.landscapeLeft, .portrait), (.portrait, .landscapeRight),
             (.portraitUpsideDown, .landscapeLeft), (.landscapeRight, .portraitUpsideDown),
             (.landscapeLeftMirrored, .portraitMirrored), (.portraitMirrored, .landscapeRightMirrored),
             (.portraitUpsideDownMirrored, .landscapeLeftMirrored), (.landscapeRightMirrored, .portraitUpsideDownMirrored):
            return .rotateClockwise
        case (.portrait, .landscapeLeft), (.landscapeRight, .portrait),
             (.landscapeLeft, .portraitUpsideDown), (.portraitUpsideDown, .landscapeRight),
             (.portraitMirrored, .landscapeLeftMirrored), (.landscapeRightMirrored, .portraitMirrored),
             (.landscapeLeftMirrored, .portraitUpsideDownMirrored), (.portraitUpsideDownMirrored, .landscapeRightMirrored):
            return .rotateCounterclockwise
        case (.portrait, .portraitMirrored), (.portraitMirrored, .portrait),
             (.portraitUpsideDown, .portraitUpsideDownMirrored), (.portraitUpsideDownMirrored, .portraitUpsideDown),
             (.landscapeLeft, .landscapeRightMirrored), (.landscapeRightMirrored, .landscapeLeft),
             (.landscapeRight, .landscapeLeftMirrored), (.landscapeLeftMirrored, .landscapeRight):
            return .flipHorizontally
        case (.portrait, .portraitUpsideDownMirrored), (.portraitUpsideDownMirrored, .portrait),
             (.portraitUpsideDown, .portraitMirrored), (.portraitMirrored, .portraitUpsideDown),
             (.landscapeLeft, .landscapeLeftMirrored), (.landscapeLeftMirrored, .landscapeLeft),
             (.landscapeRight, .landscapeRightMirrored), (.landscapeRightMirrored, .landscapeRight):
            return .flipVertically
        case (.portrait, .landscapeRightMirrored), (.landscapeRightMirrored, .portrait),
             (.landscapeRight, .portraitMirrored), (.portraitMirrored, .landscapeRight),
             (.landscapeLeft, .portraitUpsideDownMirrored), (.portraitUpsideDownMirrored, .landscapeLeft),
             (.portraitUpsideDown, .landscapeLeftMirrored), (.landscapeLeftMirrored, .portraitUpsideDown):
            return .rotateClockwiseAndFlipVertically
        case (.portraitUpsideDown, .landscapeRightMirrored), (.landscapeRightMirrored, .portraitUpsideDown),
             (.landscapeLeft, .portraitMirrored), (.portraitMirrored, .landscapeLeft),
             (.portrait, .landscapeLeftMirrored), (.landscapeLeftMirrored, .portrait),
             (.landscapeRight, .portraitUpsideDownMirrored), (.portraitUpsideDownMirrored, .landscapeRight):
            return .rotateClockwiseAndFlipHorizontally
        }
    }
}
