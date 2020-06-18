import Foundation

public class ContrastAdjustment: BasicFilter {
    @objc
    public var contrast: Float = 1.0 {
        didSet {
            renderTarget.setFragmentBufferValue(contrast, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "saturationFragment")
        ({ contrast = 1.0 })()
    }
}
