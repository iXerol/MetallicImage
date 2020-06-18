import Metal

open class BasicFilter: NSObject, ImageFilter {
    public let targets = TargetContainer()

    let renderTarget: RenderTargetState

    let operationName: String

    let textureInputSemaphore = DispatchSemaphore(value: 1)

    var previousTexture: Texture?

    /// Initialization using shaders in library
    public init(context: MIContext = .default, vertexFunctionName: String = MetallicImageLitetals.defaultVertex.rawValue, fragmentFunctionName: String, operationName: String = #file) {
        self.operationName = operationName
        renderTarget = RenderTargetState(vertexFunctionName: vertexFunctionName, fragmentFunctionName: fragmentFunctionName, context: context)
    }

    public func newTexture(_ texture: Texture) {
        _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
        defer {
            textureInputSemaphore.signal()
        }

        let outputTexture = Texture(orientation: texture.orientation,
                                    width: texture.width,
                                    height: texture.height,
                                    timingType: texture.timingType,
                                    pixelFormat: texture.pixelFormat,
                                    colorSpace: texture.colorSpace)
        guard let commandBuffer = renderTarget.context.commandQueue.makeCommandBuffer() else {
            print("Warning: \(operationName) Failed to create command buffer")
            return
        }
        commandBuffer.label = operationName
        commandBuffer.render(from: texture, to: outputTexture, targetState: renderTarget)
        commandBuffer.commit()

        textureInputSemaphore.signal()
        commandBuffer.waitUntilCompleted()
        previousTexture = outputTexture
        updateTargets(with: outputTexture)
        _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
    }

    public func transmitPreviousImage(to target: ImageConsumer, completion: ((Bool) -> Void)? = nil) {
        if let texture = previousTexture {
            target.newTexture(texture)
            completion?(true)
        } else {
            completion?(false)
        }
    }
}
