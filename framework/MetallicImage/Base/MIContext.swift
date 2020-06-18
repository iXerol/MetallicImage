import Dispatch
import Foundation
import Metal
import MetalKit
import MetalPerformanceShaders

public enum MetallicImageLitetals: String {
    case defaultVertex = "oneInputVertex"
    case defaultFragment = "passthroughFragment"
    case corlorSwizzleFragment = "colorSwizzleFragment"
}

public class MIContext {
    public static let `default`: MIContext = {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to create Metal device")
        }
        return MIContext(device: device)
    }()

    public static let bundle = Bundle(for: MIContext.self)

    public let device: MTLDevice

    public let commandQueue: MTLCommandQueue

    public let shaderLibrary: MTLLibrary

    public let textureLoader: MTKTextureLoader

    public let dispatchQueue: DispatchQueue

    public let supportsMPS: Bool

    public init(device: MTLDevice) {
        self.device = device

        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Failed to create Metal command queue")
        }
        self.commandQueue = commandQueue

        guard let metalLibraryPath = MIContext.bundle.path(forResource: "default", ofType: "metallib") else {
            fatalError("Failed to load Metal library")
        }
        do {
            shaderLibrary = try device.makeLibrary(filepath: metalLibraryPath)
        } catch {
            fatalError("Failed to load Metal library")
        }

        textureLoader = MTKTextureLoader(device: device)
        dispatchQueue = DispatchQueue(label: "com.MetallicImage.targetQueue" + UUID().uuidString, attributes: [.concurrent])
        supportsMPS = MPSSupportsMTLDevice(device)
    }
}
