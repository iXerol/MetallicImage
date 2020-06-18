import MetalPerformanceShaders

@available(iOS 10.0, *)
public class MedianBlur: BasicMPSFilter {
    @objc
    public var blurDiameter: Float = 3.0 {
        didSet {
            if useMetalPerformanceShaders {
                internalImageKernel = MPSImageMedian(device: renderTarget.context.device, kernelDiameter: Int(roundToOdd(blurDiameter)))
            } else {
                fatalError("Median Blur isno't available on pre-MPS OS versions")
            }
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context)
        ({ blurDiameter = 3.0 })()
    }
}
