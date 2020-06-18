#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

vertex SingleInputVertexIO oneInputVertex(const device packed_float2 *position [[buffer(0)]],
                                          const device packed_float2 *texturecoord [[buffer(1)]],
                                          uint vid [[vertex_id]]) {
    SingleInputVertexIO outputVertices;

    outputVertices.position = float4(position[vid], 0, 1.0);
    outputVertices.textureCoordinate = texturecoord[vid];

    return outputVertices;
}

fragment half4 passthroughFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                   texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    return color;
}

fragment half4 colorSwizzleFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                    texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).bgra;

    return color;
}
