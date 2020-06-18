import Foundation
public class Sharpen: BasicFilter {
    @objc
    public var sharpness: Float = 0.0 {
        didSet {
            renderTarget.setFragmentBufferValue(sharpness, at: 0)
        }
    }

    public init() {
        super.init(vertexFunctionName: "sharpenVertex", fragmentFunctionName: "sharpenFragment")
        ({ sharpness = 0.0 })()
    }

    public override func newTexture(_ texture: Texture) {
        renderTarget.extraVertexBytes = [Float(texture.width), Float(texture.height)]
        super.newTexture(texture)
    }
}
