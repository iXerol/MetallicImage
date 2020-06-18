import MetalPerformanceShaders

@available(iOS 11.0, tvOS 11.0, *)
public class BilinearScale: BasicMPSFilter {
    private var scaleTransform = MPSScaleTransform(scaleX: 1, scaleY: 1, translateX: 0, translateY: 0)

    @objc
    public var scaleX: Float {
        get {
            return Float(scaleTransform.scaleX)
        }
        set {
            scaleTransform.scaleX = Double(newValue)
        }
    }

    @objc
    public var scaleY: Float {
        get {
            return Float(scaleTransform.scaleY)
        }
        set {
            scaleTransform.scaleY = Double(newValue)
        }
    }

    @objc
    public var translateX: Float {
        get {
            return Float(scaleTransform.translateX)
        }
        set {
            scaleTransform.translateX = Double(newValue)
        }
    }

    @objc
    public var translateY: Float {
        get {
            return Float(scaleTransform.translateY)
        }
        set {
            scaleTransform.translateY = Double(newValue)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        if useMetalPerformanceShaders {
            internalImageKernel = MPSImageBilinearScale(device: renderTarget.context.device)
        } else {
            fatalError("Bilinear Scale isno't available on pre-MPS OS versions")
        }
    }

    public override func renderWithShader(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        if useMetalPerformanceShaders {
            withUnsafePointer(to: &scaleTransform) { scale in
                (internalImageKernel as? MPSImageBilinearScale)?.scaleTransform = scale
                internalImageKernel?.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destinationTexture)
            }
        }
    }
}
