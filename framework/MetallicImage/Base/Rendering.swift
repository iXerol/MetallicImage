import CoreGraphics
import Metal

class RenderTargetState {
    var renderPipelineState: MTLRenderPipelineState
    var renderPassDescriptor: MTLRenderPassDescriptor {
        let rpd = MTLRenderPassDescriptor()
        rpd.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        rpd.colorAttachments[0].storeAction = .store
        rpd.colorAttachments[0].loadAction = .clear
        return rpd
    }

    let context: MIContext
    var textureCoord: MTLBuffer?
    internal private(set) var fragmentBufferValues: [[Float]] = []
    var extraVertexBytes: [Float]?

    init(vertexFunctionName: String,
         fragmentFunctionName: String,
         context: MIContext = .default) {
        self.context = context
        let library = context.shaderLibrary
        guard let vertexFunction = library.makeFunction(name: vertexFunctionName) else {
            fatalError("Failed to compile vertex function \(vertexFunctionName)")
        }
        guard let fragmentFunction = library.makeFunction(name: fragmentFunctionName) else {
            fatalError("Failed to compile fragment function \(fragmentFunctionName)")
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        descriptor.rasterSampleCount = 1
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        do {
            var reflection: MTLAutoreleasedRenderPipelineReflection?
            renderPipelineState = try context.device.makeRenderPipelineState(descriptor: descriptor, options: [.bufferTypeInfo, .argumentInfo], reflection: &reflection)
            if let fragmentArguments = reflection?.fragmentArguments {
                let fragmentBufferCount = fragmentArguments.filter { $0.type == .buffer }.count
                fragmentBufferValues = [[Float]](repeating: [], count: fragmentBufferCount)
            }
        } catch {
            fatalError("Could not create render pipeline state for vertex:\(vertexFunctionName), fragment:\(fragmentFunctionName), error:\(error)")
        }
    }

    convenience init(context: MIContext = .default) {
        self.init(vertexFunctionName: MetallicImageLitetals.defaultVertex.rawValue,
                  fragmentFunctionName: MetallicImageLitetals.defaultFragment.rawValue,
                  context: context)
    }

    func updateCoordinateIfNeeded(_ texture: Texture, for orientation: ImageOrientation = .portrait) {
        var coordinate = texture.coordinate(for: orientation)
        textureCoord = context.device.makeBuffer(bytes: &coordinate, length: MemoryLayout.size(ofValue: coordinate), options: [])
        textureCoord?.label = "Texture Coordination"
    }

    func setFragmentBufferValue(_ value: [Float], at index: Int) {
        guard (0 ..< fragmentBufferValues.count).contains(index) else {
            fatalError("No such fragment buffer index")
        }
        fragmentBufferValues[index] = value
    }

    func setFragmentBufferValue(_ value: Float, at index: Int) {
        setFragmentBufferValue([value], at: index)
    }
}
