//
//  PictureInput.swift
//  MetallicImage
//
//  Created by Xerol Wong on 3/22/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif
import MetalKit

public class PictureInput: ImageSource {
    var internalTexture: Texture?
    var internalImage: CGImage?
    let orientation: ImageOrientation
    public let targets = TargetContainer()
    let context: MIContext

    public init(image: CGImage, orientation: ImageOrientation = .portrait, context: MIContext = .default) {
        internalImage = image
        self.orientation = orientation
        self.context = context
    }

    #if canImport(UIKit)

    public convenience init(image: UIImage, orientation: ImageOrientation) {
        self.init(image: image.cgImage!, orientation: orientation)
    }

    public convenience init(image: UIImage) {
        self.init(image: image, orientation: ImageOrientation(with: image.imageOrientation))
    }

    #else

    public convenience init(image: NSImage, orientation: ImageOrientation = .portrait, context: MIContext = .default) {
        self.init(image: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!, orientation: orientation, context: context)
    }

    #endif

    public func processImage(synchronously: Bool = false) {
        if synchronously {
            if let texture = internalTexture {
                updateTargets(with: texture)
            } else {
                guard let image = internalImage else {
                    return
                }
                do {
                    let textureLoader = context.textureLoader
                    let texture = try textureLoader.newTexture(cgImage: image, options: [.SRGB: false])
                    internalImage = nil
                    internalTexture = Texture(texture: texture, orientation: orientation, colorSpace: image.colorSpace)
                    updateTargets(with: internalTexture!)
                } catch {
                    fatalError("Failed to load texture: \(error)")
                }
            }
        } else {
            if let texture = internalTexture {
                context.dispatchQueue.async {
                    self.updateTargets(with: texture)
                }
            } else {
                guard let image = internalImage else {
                    return
                }
                let textureLoader = context.textureLoader
                textureLoader.newTexture(cgImage: image, options: [.SRGB: false]) { texture, error in
                    guard error == nil else {
                        fatalError("Failed to load texture: \(error!)")
                    }
                    guard let texture = texture else {
                        fatalError("Texture is nil.")
                    }
                    self.internalImage = nil
                    self.internalTexture = Texture(texture: texture, orientation: self.orientation, colorSpace: image.colorSpace)
                    self.context.dispatchQueue.async {
                        self.updateTargets(with: self.internalTexture!)
                    }
                }
            }
        }
    }

    public func transmitPreviousImage(to target: ImageConsumer, completion: ((Bool) -> Void)? = nil) {
        if let texture = internalTexture {
            target.newTexture(texture)
            completion?(true)
        } else {
            completion?(false)
        }
    }
}
