//
//  PictureOutput.swift
//  MetallicImage
//
//  Created by Xerol Wong on 3/30/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

#if canImport(UIKit)
import UIKit
public typealias PlatformImageType = UIImage
#else
import Cocoa
public typealias PlatformImageType = NSImage
#endif

public class PictureOutput: ImageConsumer {
    public var imageAvailableCallback: ((PlatformImageType) -> Void)?
    var renderTarget: RenderTargetState
    public var orientation: ImageOrientation = .portrait

    public init(context: MIContext = .default) {
        renderTarget = RenderTargetState(
            vertexFunctionName: MetallicImageLitetals.defaultVertex.rawValue,
             fragmentFunctionName: MetallicImageLitetals.corlorSwizzleFragment.rawValue,
             context: context)
    }

    public func newTexture(_ texture: Texture) {
        guard let commandBuffer = renderTarget.context.commandQueue.makeCommandBuffer() else {
            fatalError("Failed to create command buffer")
        }

        let outputTexture: Texture
        if texture.orientation.rotationNeeded(for: orientation).flipsDimensions() {
            outputTexture = Texture(device: texture.texture.device,
                                    orientation: orientation,
                                    width: texture.height,
                                    height: texture.width,
                                    colorSpace: texture.colorSpace)
        } else {
            outputTexture = Texture(device: texture.texture.device,
                                    orientation: orientation,
                                    width: texture.width,
                                    height: texture.height,
                                    colorSpace: texture.colorSpace)
        }
        commandBuffer.render(from: texture, to: outputTexture, targetState: renderTarget)
        commandBuffer.enqueue()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let image = outputTexture.image {
            imageAvailableCallback?(image)
        }
    }
}
