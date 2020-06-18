import MetalPerformanceShaders

public class AreaMin: BasicMPSFilter {
    @objc
    public var kernelRadius: Float = 2.0 {
        didSet {
            if useMetalPerformanceShaders {
                let kernelSize = roundToOdd(kernelRadius) // MPS area min kernels need to be odd
                internalImageKernel = MPSImageAreaMin(device: renderTarget.context.device, kernelWidth: kernelSize, kernelHeight: kernelSize)
            } else {
                fatalError("Area Min isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        ({ kernelRadius = 2.0 })()
    }
}
