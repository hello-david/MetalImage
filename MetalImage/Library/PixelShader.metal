//
//  Extension.metal
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#include <metal_stdlib>
using namespace metal;

struct SingleInputVertexIO {
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
};

constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);

#pragma mark - 饱和度
fragment half4 saturationFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                  constant float &saturation [[buffer(2)]],
                                  texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    half luminance = dot(textureColor.rgb, luminanceWeighting);
    half3 greyScaleColor = half3(luminance);
    half4 color = half4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.w);
    
    return color;
}

#pragma mark - 亮度
fragment half4 luminanceRangeFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                      constant float &rangeReduction [[buffer(2)]],
                                      texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    half luminance = dot(textureColor.rgb, luminanceWeighting);
    half luminanceRatio = ((0.5 - luminance) * rangeReduction);
    half4 color = half4((textureColor.rgb) + (luminanceRatio), textureColor.w);
    
    return color;
}

#pragma mark - 对比度
fragment half4 contrastFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                constant float &contrast [[buffer(2)]],
                                texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    half4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    half4 color = half4(((textureColor.rgb - half3(0.5)) * contrast + half3(0.5)), textureColor.w);
    return color;
}

#pragma mark - 色调
constant float4 kRGBToYPrime = float4(0.299, 0.587, 0.114, 0.0);
constant float4 kRGBToI = float4(0.595716, -0.274453, -0.321263, 0.0);
constant float4 kRGBToQ = float4(0.211456, -0.522591, 0.31135, 0.0);

constant float4 kYIQToR = float4(1.0, 0.9563, 0.6210, 0.0);
constant float4 kYIQToG = float4(1.0, -0.2721, -0.6474, 0.0);
constant float4 kYIQToB = float4(1.0, -1.1070, 1.7046, 0.0);

fragment float4 hueFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                            constant float &hueAdjust [[buffer(2)]],
                            texture2d<float> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    float4 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    // Convert to YIQ
    float YPrime = dot(textureColor, kRGBToYPrime);
    float I = dot(textureColor, kRGBToI);
    float Q = dot(textureColor, kRGBToQ);
    
    // Calculate the hue and chroma
    float hue = atan2(Q, I);
    float chroma = sqrt(I * I + Q * Q);
    
    // Make the user's adjustments
    hue += (-hueAdjust);
    
    // Convert back to YIQ
    Q = chroma * sin (hue);
    I = chroma * cos (hue);
    
    // Convert back to RGB
    float4 yIQ = float4(YPrime, I, Q, 0.0);
    textureColor.r = dot(yIQ, kYIQToR);
    textureColor.g = dot(yIQ, kYIQToG);
    textureColor.b = dot(yIQ, kYIQToB);
    
    return textureColor;
}
