import Metal

public let standardImagePosition: [Float] = [-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0]

extension MTLCommandBuffer {
    func render(from inTexture: Texture, to outTexture: Texture, targetState: RenderTargetState) {
        guard device === targetState.context.device && inTexture.texture.device === outTexture.texture.device && inTexture.texture.device === targetState.context.device else {
            fatalError("Could not render in different devices.")
        }

        targetState.updateCoordinateIfNeeded(inTexture, for: outTexture.orientation)

        let rpd = targetState.renderPassDescriptor
        rpd.colorAttachments[0].texture = outTexture.texture

        guard let renderEncoder = self.makeRenderCommandEncoder(descriptor: rpd) else {
            fatalError("Failed to create render command encoder")
        }

        renderEncoder.setRenderPipelineState(targetState.renderPipelineState)
        renderEncoder.setFrontFacing(.clockwise)
        renderEncoder.setVertexBytes(standardImagePosition, length: standardImagePosition.count * MemoryLayout<Float>.size, index: 0)
        renderEncoder.setVertexBuffer(targetState.textureCoord, offset: 0, index: 1)
        if let vertexBytes = targetState.extraVertexBytes {
            renderEncoder.setVertexBytes(vertexBytes, length: MemoryLayout<Float>.size * vertexBytes.count, index: 2)
        }

        renderEncoder.setFragmentTexture(inTexture.texture, index: 0)
        for (index, bufferValue) in targetState.fragmentBufferValues.enumerated() {
            renderEncoder.setFragmentBytes(bufferValue, length: MemoryLayout<Float>.size * bufferValue.count, index: index + 1)
        }
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}
