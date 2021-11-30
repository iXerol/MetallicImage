//
//  ImageView.swift
//  MetallicImage
//
//  Created by Xerol Wong on 3/16/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import MetalKit
import MetalPerformanceShaders
import QuartzCore

public class ImageView: MTKView, ImageConsumer {
    var currentTexture: Texture?

    var renderTarget: RenderTargetState
    public var orientation: ImageOrientation = .portrait

#if targetEnvironment(simulator)
    @available(iOS 13.0, macOS 10.11, tvOS 13.0, *)
    private var metalLayer: CAMetalLayer? {
        layer as? CAMetalLayer
    }
#else
    private var metalLayer: CAMetalLayer? {
        layer as? CAMetalLayer
    }
#endif

    public init(frame frameRect: CGRect = .zero, context: MIContext = .default) {
        renderTarget = RenderTargetState(context: context)
        super.init(frame: frameRect, device: context.device)
        commonInit()
    }

    public required init(coder: NSCoder) {
        renderTarget = RenderTargetState()
        super.init(coder: coder)

        device = MIContext.default.device
        commonInit()
    }

    func commonInit() {
#if targetEnvironment(simulator)
        if #available(iOS 13.0, macOS 10.13, tvOS 13.0, *) {
            metalLayer?.allowsNextDrawableTimeout = false
        }
#else
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, *) {
            metalLayer?.allowsNextDrawableTimeout = false
        }
#endif
        framebufferOnly = false
        autoResizeDrawable = true
        enableSetNeedsDisplay = false
        isPaused = true
    }

    override public func draw(_ rect: CGRect) {
        if let currentDrawable = self.currentDrawable, let currentTexture = currentTexture {
            guard let commandBuffer = renderTarget.context.commandQueue.makeCommandBuffer() else {
                fatalError("Failed to create command buffer")
            }
            let targetTexture = Texture(texture: currentDrawable.texture, orientation: orientation)
            commandBuffer.render(from: currentTexture, to: targetTexture, targetState: renderTarget)
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
        }
    }

    public func newTexture(_ texture: Texture) {
        currentTexture = texture
        if texture.orientation.rotationNeeded(for: orientation).flipsDimensions() {
            drawableSize = texture.size.flipped()
        } else {
            drawableSize = texture.size
        }
        if #available(iOS 13.0, macOS 10.12, tvOS 13.0, *) {
            DispatchQueue.main.async {
                self.metalLayer?.colorspace = texture.colorSpace
            }
        }
        draw()
    }
}
