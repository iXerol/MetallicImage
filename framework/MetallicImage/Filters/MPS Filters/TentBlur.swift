import MetalPerformanceShaders

public class TentBlur: BasicMPSFilter {
    @objc
    public var blurDiameter: Float = 2.0 {
        didSet {
            if useMetalPerformanceShaders {
                let kernelSize = roundToOdd(blurDiameter) // MPS tent blur kernels need to be odd
                internalImageKernel = MPSImageTent(device: renderTarget.context.device, kernelWidth: kernelSize, kernelHeight: kernelSize)
            } else {
                fatalError("Tent Blur isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        ({ blurDiameter = 2.0 })()
    }
}
