import Foundation

public class BrightnessAdjustment: BasicFilter {
    @objc
    public var brightness: Float = 0.0 {
        didSet {
            renderTarget.setFragmentBufferValue(brightness, at: 0)
        }
    }

    public init(context: MIContext = .default) {
        super.init(context: context, fragmentFunctionName: "brightnessFragment")
        ({ brightness = 0.0 })()
    }
}
