import MetalPerformanceShaders

open class BasicMPSFilter: BasicFilter {
    var internalImageKernel: MPSUnaryImageKernel?
    public var useMetalPerformanceShaders: Bool = false {
        didSet {
            if !renderTarget.context.supportsMPS {
                print("Warning: Metal Performance Shaders are not supported on this device")
                useMetalPerformanceShaders = false
            }
        }
    }

    /// Initialization using Metal Performance Shaders
    public init(context: MIContext = .default, operationName: String = #file) {
        super.init(context: context, fragmentFunctionName: MetallicImageLitetals.defaultFragment.rawValue)

        if renderTarget.context.supportsMPS {
            useMetalPerformanceShaders = true
        } else {
            print("Warning: Metal Performance Shaders are not supported on this device")
            useMetalPerformanceShaders = false
        }
    }

    public override func newTexture(_ texture: Texture) {
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
        if useMetalPerformanceShaders {
            renderWithShader(commandBuffer: commandBuffer, sourceTexture: texture.texture, destinationTexture: outputTexture.texture)
        } else {
            commandBuffer.render(from: texture, to: outputTexture, targetState: renderTarget)
        }
        commandBuffer.commit()

        textureInputSemaphore.signal()
        commandBuffer.waitUntilCompleted()
        previousTexture = outputTexture
        updateTargets(with: outputTexture)
        _ = textureInputSemaphore.wait(timeout: DispatchTime.distantFuture)
    }

    public func renderWithShader(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        internalImageKernel?.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destinationTexture)
    }
}

extension BasicMPSFilter {
    func roundToOdd(_ number: Float) -> Int {
        return 2 * Int(floor(number / 2.0)) + 1
    }
}
