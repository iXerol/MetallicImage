//
//  Texture.swift
//  MetallicImage
//
//  Created by Xerol Wong on 3/21/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import CoreGraphics
import CoreMedia
import Metal

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public class Texture {
    public enum TimingType {
        case stillImage
        case videoFrame(time: CMTime)

        var cmTime: CMTime? {
            switch self {
            case .stillImage:
                return nil
            case .videoFrame(time: let time):
                return time
            }
        }
    }

    public let timingType: TimingType

    public let texture: MTLTexture

    public var orientation: ImageOrientation

    public let colorSpace: CGColorSpace

    public var width: Int {
        return texture.width
    }

    public var height: Int {
        return texture.height
    }

    public var size: CGSize {
        return CGSize(width: width, height: height)
    }

    public var pixelFormat: MTLPixelFormat {
        return texture.pixelFormat
    }

    public init(texture: any MTLTexture,
                orientation: ImageOrientation,
                timingType: TimingType = .stillImage,
                colorSpace: CGColorSpace? = nil) {
        self.texture = texture
        self.orientation = orientation
        self.timingType = timingType
        self.colorSpace = colorSpace ?? CGColorSpaceCreateDeviceRGB()
    }

    public init(device: MTLDevice = MIContext.default.device,
                orientation: ImageOrientation,
                width: Int,
                height: Int,
                timingType: TimingType = .stillImage,
                pixelFormat: MTLPixelFormat = .bgra8Unorm,
                mipmapped: Bool = false,
                colorSpace: CGColorSpace? = nil) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: mipmapped)
        textureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]

        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            fatalError("Failed to create new texture of size: (\(width), \(height))")
        }

        self.texture = texture
        self.orientation = orientation
        self.timingType = timingType
        self.colorSpace = colorSpace ?? CGColorSpaceCreateDeviceRGB()
    }
}

// MARK: Coordinate

extension Texture {
    public struct ImageCoordinate {
        let bottomLeftX: Float
        let bottomLeftY: Float

        let bottomRightX: Float
        let bottomRightY: Float

        let topLeftX: Float
        let topLeftY: Float

        let topRightX: Float
        let topRightY: Float

        public init(_ bottomLeftX: Float,
                    _ bottomLeftY: Float,
                    _ bottomRightX: Float,
                    _ bottomRightY: Float,
                    _ topLeftX: Float,
                    _ topLeftY: Float,
                    _ topRightX: Float,
                    _ topRightY: Float) {
            self.bottomLeftX = bottomLeftX
            self.bottomLeftY = bottomLeftY
            self.bottomRightX = bottomRightX
            self.bottomRightY = bottomRightY
            self.topLeftX = topLeftX
            self.topLeftY = topLeftY
            self.topRightX = topRightX
            self.topRightY = topRightY
        }

        static let noRotation = ImageCoordinate(0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0)
        static let rotateClockwise = ImageCoordinate(1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
        static let rotateCounterclockwise = ImageCoordinate(0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0)
        static let rotate180 = ImageCoordinate(1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 1.0)
        static let flipHorizontally = ImageCoordinate(1.0, 1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0)
        static let flipVertically = ImageCoordinate(0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0)
        static let rotateClockwiseAndFlipVertically = ImageCoordinate(0.0, 1.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0)
        static let rotateClockwiseAndFlipHorizontally = ImageCoordinate(1.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0)
    }

    func coordinate(for orientation: ImageOrientation) -> ImageCoordinate {
        let rotation = self.orientation.rotationNeeded(for: orientation)
        switch rotation {
        case .noRotation:
            return .noRotation
        case .rotateClockwise:
            return .rotateClockwise
        case .rotate180:
            return .rotate180
        case .rotateCounterclockwise:
            return .rotateCounterclockwise
        case .flipHorizontally:
            return .flipHorizontally
        case .flipVertically:
            return .flipVertically
        case .rotateClockwiseAndFlipHorizontally:
            return .rotateClockwiseAndFlipHorizontally
        case .rotateClockwiseAndFlipVertically:
            return .rotateClockwiseAndFlipVertically
        }
    }
}

// MARK: Image

extension Texture {
    /// Return the CGImage format of the texture
    public var cgImage: CGImage? {
        let imageByteSize = height * width * 4
        let outputBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: imageByteSize)
        texture.getBytes(outputBytes, bytesPerRow: MemoryLayout<UInt8>.size * width * 4, bytesPerImage: 0, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, slice: 0)

        guard let dataProvider = CGDataProvider(dataInfo: nil, data: outputBytes, size: imageByteSize, releaseData: { _, data, _ in
            data.deallocate()
        }) else {
            fatalError("Failed to create CGDataProvider")
        }
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    #if canImport(UIKit)
    /// Return the UIImage format of the texture
    public var image: UIImage? {
        guard let cgImage = self.cgImage else {
        return nil
        }
        return UIImage(cgImage: cgImage)
    }

    #else
    /// Return the NSImage format of the texture
    public var image: NSImage? {
        guard let cgImage = self.cgImage else {
        return nil
        }
        return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
    }
    #endif

    func callAsFunction() -> some MTLTexture {
        texture
    }
}
