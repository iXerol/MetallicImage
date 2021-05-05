//
//  ShaderTypes.h
//  MetallicImage
//
//  Created by Xerol Wong on 4/22/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

// Luminance Constants
constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);  // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham

typedef struct {
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
} SingleInputVertexIO;

#endif /* ShaderTypes_h */
