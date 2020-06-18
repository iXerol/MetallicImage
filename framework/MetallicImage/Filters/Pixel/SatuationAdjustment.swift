import Foundation

public class SaturationAdjustment: BasicFilter {
    @objc
    public var saturation: Float = 1.0 {
        didSet {
            renderTarget.setFragmentBufferValue(saturation, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "saturationFragment")
        ({ saturation = 1.0 })()
    }
}
