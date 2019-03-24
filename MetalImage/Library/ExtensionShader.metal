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

#pragma mark - 锐化
struct SharpenVertexOutput {
    float4 position [[position]];
    float2 textureCoordinate [[user(texturecoord)]];
    
    float2 leftTextureCoordinate;
    float2 rightTextureCoordinate;
    float2 topTextureCoordinate;
    float2 bottomTextureCoordinate;
    
    float centerMultiplier;
    float edgeMultiplier;
};

struct SharpenVertexParameter {
    float imageWidthFactor;
    float imageHeightFactor;
    float sharpness;
};

vertex SharpenVertexOutput sharpenVertex(device packed_float2 *position [[buffer(0)]],
                                         device packed_float2 *texturecoord [[buffer(1)]],
                                         constant SharpenVertexParameter &sharpenPara [[buffer(2)]],
                                         uint vid [[vertex_id]]) {
    float2 texture2dCoord = texturecoord[vid];
    
    SharpenVertexOutput sharpenIO;
    sharpenIO.position = float4(position[vid], 0, 1.0);
    
    float2 widthStep = float2(sharpenPara.imageWidthFactor, 0.0);
    float2 heightStep = float2(0.0, sharpenPara.imageHeightFactor);
    
    sharpenIO.textureCoordinate = texture2dCoord;
    sharpenIO.leftTextureCoordinate = texture2dCoord - widthStep;
    sharpenIO.rightTextureCoordinate = texture2dCoord + widthStep;
    sharpenIO.topTextureCoordinate = texture2dCoord + heightStep;
    sharpenIO.bottomTextureCoordinate = texture2dCoord - heightStep;
    
    sharpenIO.centerMultiplier = 1.0 + 4.0 * sharpenPara.sharpness;
    sharpenIO.edgeMultiplier = sharpenPara.sharpness;
    
    return sharpenIO;
}

fragment half4 sharpenFragment(SharpenVertexOutput fragmentInput [[stage_in]],
                                texture2d<half> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    
    half3 textureColor = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate).rgb * fragmentInput.centerMultiplier;
    half3 leftTextureColor = inputTexture.sample(quadSampler, fragmentInput.leftTextureCoordinate).rgb * fragmentInput.edgeMultiplier;
    half3 rightTextureColor = inputTexture.sample(quadSampler, fragmentInput.rightTextureCoordinate).rgb * fragmentInput.edgeMultiplier;
    half3 topTextureColor = inputTexture.sample(quadSampler, fragmentInput.topTextureCoordinate).rgb * fragmentInput.edgeMultiplier;
    half3 bottomTextureColor = inputTexture.sample(quadSampler, fragmentInput.bottomTextureCoordinate).rgb * fragmentInput.edgeMultiplier;
    
    half4 color = half4((textureColor - (leftTextureColor + rightTextureColor + topTextureColor + bottomTextureColor)), inputTexture.sample(quadSampler, fragmentInput.bottomTextureCoordinate).a);
    
    return color;
}

#pragma mark - 颜色矩阵

