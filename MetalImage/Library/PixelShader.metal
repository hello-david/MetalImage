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

#pragma mark - 颜色查找表
struct LutInfo {
    unsigned int maxColorValue;   // lut每个分量的有多少种颜色最大取值
    unsigned int latticeCount;    // 每排晶格数量
    unsigned int width;           // lut图片宽度
    unsigned int height;          // lut图片高度
};
fragment float4 lookUpTableFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                    constant float &intensity [[buffer(2)]],
                                    constant LutInfo &lutInfo [[buffer(3)]],
                                    texture2d<float> inputTexture [[texture(0)]],
                                    texture2d<float> lutTexture [[texture(1)]]) {
    constexpr sampler quadSampler;
    float4 px = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    // B通道对应LUT上的数值
    float blueColor = px.b * lutInfo.maxColorValue;
    
    // 计算临近两个B通道所在的方形LUT单元格（从左到右从，上到下排列）
    float2 quad_l, quad_h;
    quad_l.y = floor(floor(blueColor) / lutInfo.latticeCount);
    quad_l.x = floor(blueColor) - quad_l.y * lutInfo.latticeCount;
    quad_h.y = floor(ceil(blueColor) / lutInfo.latticeCount);
    quad_h.x = ceil(blueColor) - (quad_h.y * lutInfo.latticeCount);
    
    // 单位像素上的中心偏移量
    float px_length = 1.0 / lutInfo.width;
    float cell_length = 1.0 / lutInfo.latticeCount;
    
    // 根据RG、B偏移量计算LUT上对应的(x,y)
    float2 lut_pos_l, lut_pos_h;
    lut_pos_l.x = (quad_l.x * cell_length) + px_length / 2.0 + ((cell_length - px_length) * px.r);
    lut_pos_l.y = (quad_l.y * cell_length) + px_length / 2.0 + ((cell_length - px_length) * px.g);
    lut_pos_h.x = (quad_h.x * cell_length) + px_length / 2.0 + ((cell_length - px_length) * px.r);
    lut_pos_h.y = (quad_h.y * cell_length) + px_length / 2.0 + ((cell_length - px_length) * px.g);
    
    // 获取映射的LUT颜色
    float4 graded_color_l = lutTexture.sample(quadSampler, lut_pos_l);
    float4 graded_color_h = lutTexture.sample(quadSampler, lut_pos_h);
    float4 graded_color = mix(graded_color_l, graded_color_h, fract(blueColor));
    
    // 根据intensity定制效果程度
    float4 newColor = mix(px, float4(graded_color.rgb, px.w), intensity);
    return newColor;
}
