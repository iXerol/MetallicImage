#include <metal_stdlib>
#include "ShaderTypes.h"
using namespace metal;

#pragma mark - Brightness Adjustment
fragment half4 brightnessFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant float &brightness [[ buffer(1) ]]) {
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    return half4(color.rgb + brightness, color.a);
}

#pragma mark - Saturation Adjustment
fragment half4 saturationFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                  texture2d<half> inputTexture [[texture(0)]],
                                  constant float &saturation [[ buffer(1) ]]) {
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    half luminance = dot(color.rgb, luminanceWeighting);

    return half4(mix(half3(luminance), color.rgb, half(saturation)), color.a);
}
#pragma mark - Contrast Adjustment
fragment half4 contrastFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                constant float &contrast [[buffer(1)]],
                                texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    half4 color = half4(((textureColor.rgb - half3(0.5)) * contrast + half3(0.5)), textureColor.w);
    return color;
}

#pragma mark - Hue Adjustment
// Hue Constants
constant half4 kRGBToYPrime = half4(0.299, 0.587, 0.114, 0.0);
constant half4 kRGBToI = half4(0.595716, -0.274453, -0.321263, 0.0);
constant half4 kRGBToQ = half4(0.211456, -0.522591, 0.31135, 0.0);

constant half4 kYIQToR = half4(1.0, 0.9563, 0.6210, 0.0);
constant half4 kYIQToG = half4(1.0, -0.2721, -0.6474, 0.0);
constant half4 kYIQToB = half4(1.0, -1.1070, 1.7046, 0.0);

fragment half4 hueFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                           texture2d<half> inputTexture [[texture(0)]],
                           constant float &hueAdjust [[ buffer(1) ]]) {
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    // Convert to YIQ
    float YPrime = dot (color, kRGBToYPrime);
    float I = dot (color, kRGBToI);
    float Q = dot (color, kRGBToQ);

    // Calculate the hue and chroma
    float hue = atan2(Q, I);
    float chroma = sqrt(I * I + Q * Q);

    // Make the user's adjustments
    hue += (hueAdjust); //why negative rotation?

    // Convert back to YIQ
    Q = chroma * sin (hue);
    I = chroma * cos (hue);

    // Convert back to RGB
    half4 yIQ = half4(YPrime, I, Q, 0.0);
    color.r = dot(yIQ, kYIQToR);
    color.g = dot(yIQ, kYIQToG);
    color.b = dot(yIQ, kYIQToB);

    // Return result
    return color;
}

#pragma mark - White Balance Adjustment
constant half3 warmFilter = half3(0.93, 0.54, 0.0);
constant half3x3 RGBtoYIQ = half3x3(half3(0.299, 0.587, 0.114),
                                    half3(0.596, -0.274, -0.322),
                                    half3(0.212, -0.523, 0.311));
constant half3x3 YIQtoRGB = half3x3(half3(1.0, 0.956, 0.621),
                                    half3(1.0, -0.272, -0.647),
                                    half3(1.0, -1.105, 1.702));

typedef struct {
    float tint;
    float temperature;
} WhiteBalanceInfo;

fragment half4 whiteBalanceFragmentShader(SingleInputVertexIO fragmentInput [[stage_in]],
                                          texture2d<half> inputTexture [[texture(0)]],
                                          constant WhiteBalanceInfo &whiteBalanceInfo [[ buffer(1) ]]) {
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    half3 yiq = RGBtoYIQ * color.rgb; //adjusting tint
    yiq.b = clamp(yiq.b + whiteBalanceInfo.tint * 0.5226 * 0.1, -0.5226, 0.5226);
    half3 rgb = YIQtoRGB * yiq;

    half3 processed = half3((rgb.r < 0.5 ? (2.0 * rgb.r * warmFilter.r) : (1.0 - 2.0 * (1.0 - rgb.r) * (1.0 - warmFilter.r))), //adjusting temperature
                            (rgb.g < 0.5 ? (2.0 * rgb.g * warmFilter.g) : (1.0 - 2.0 * (1.0 - rgb.g) * (1.0 - warmFilter.g))),
                            (rgb.b < 0.5 ? (2.0 * rgb.b * warmFilter.b) : (1.0 - 2.0 * (1.0 - rgb.b) * (1.0 - warmFilter.b))));

    return half4(mix(rgb, processed, whiteBalanceInfo.temperature), color.a);
}

#pragma mark - Sharpen
typedef struct {
    float4 position [[position]];

    float2 textureCoordinate [[user(textureCoordinate)]];
    float2 leftTextureCoordinate [[user(leftTextureCoordinate)]];
    float2 rightTextureCoordinate [[user(rightTextureCoordinate)]];
    float2 topTextureCoordinate [[user(topTextureCoordinate)]];
    float2 bottomTextureCoordinate [[user(bottomTextureCoordinate)]];
} SharpenVertexIO;

typedef struct {
    float width;
    float height;
} TextureSize;

vertex SharpenVertexIO sharpenVertex(const device packed_float2 *position [[buffer(0)]],
                                     const device packed_float2 *textureCoordinate [[buffer(1)]],
                                     constant TextureSize &size [[buffer(2)]],
                                     uint vid [[vertex_id]]) {
    SharpenVertexIO outputVertices;

    outputVertices.position = float4(position[vid], 0, 1.0);

    float2 widthStep = float2(1.0 / size.width, 0.0);
    float2 heightStep = float2(0.0, 1.0 / size.height);

    outputVertices.textureCoordinate = textureCoordinate[vid];
    outputVertices.leftTextureCoordinate = textureCoordinate[vid] - widthStep;
    outputVertices.rightTextureCoordinate = textureCoordinate[vid] + widthStep;
    outputVertices.topTextureCoordinate = textureCoordinate[vid] + heightStep;
    outputVertices.bottomTextureCoordinate = textureCoordinate[vid] - heightStep;

    return outputVertices;
}

fragment half4 sharpenFragment(SharpenVertexIO fragmentInput [[stage_in]],
                               texture2d<half> inputTexture [[texture(0)]],
                               constant float &sharpness [[buffer(1)]]) {
    constexpr sampler quadSampler;
    half3 centerColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).rgb;
    half3 leftColor = inputTexture.sample(quadSampler, fragmentInput.leftTextureCoordinate).rgb;
    half3 rightColor = inputTexture.sample(quadSampler, fragmentInput.rightTextureCoordinate).rgb;
    half3 topColor = inputTexture.sample(quadSampler, fragmentInput.topTextureCoordinate).rgb;
    half3 bottomColor = inputTexture.sample(quadSampler, fragmentInput.bottomTextureCoordinate).rgb;

    half edgeMultiplier = half(sharpness);
    half centerMultiplier = 1.0 + 4.0 * edgeMultiplier;

    return half4((centerColor * centerMultiplier - (leftColor * edgeMultiplier + rightColor * edgeMultiplier+ topColor * edgeMultiplier + bottomColor * edgeMultiplier)), inputTexture.sample(quadSampler, fragmentInput.bottomTextureCoordinate).a);

}
