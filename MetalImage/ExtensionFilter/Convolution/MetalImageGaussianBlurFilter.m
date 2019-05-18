//
//  MetalImageGaussianBlurFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageGaussianBlurFilter.h"
// 使用https://github.com/BradLarson/GPUImage/blob/master/framework/Source/GPUImageGaussianBlurFilter.m这个脚本

NSString *const MetalImageGaussinDefaultVertex = METAL_SHADER_STRING
(
 using namespace metal;
 
 struct SingleInputVertexIO {
     float4 position [[position]];
     float2 textureCoordinate [[user(texturecoord)]];
 };
 
 vertex SingleInputVertexIO gaussianVertex(device packed_float2 *position [[buffer(0)]],
                                           device packed_float2 *texturecoord [[buffer(1)]],
                                           uint vid [[vertex_id]]) {
     SingleInputVertexIO outputVertices;
     outputVertices.position = float4(position[vid], 0, 1.0);
     outputVertices.textureCoordinate = texturecoord[vid];
     
     return outputVertices;
 }
 );

NSString *const kMetalImageGaussinDefaultFragment = METAL_SHADER_STRING
(
 fragment half4 gaussianFragment(SingleInputVertexIO fragmentInput [[stage_in]],
                                 texture2d<half> inputTexture [[texture(0)]]) {
     constexpr sampler quadSampler;
     half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
     return color;
 }
 );

typedef struct MetalImageGaussianParameter {
    float texelWidthOffset;
    float texelHeightOffset;
} MetalImageGaussianParameter;

@interface MetalImageGaussianBlurFilter() {
    MetalImageGaussianParameter _currentParam;
    MetalImageGaussianParameter _verticalParam;
    MetalImageGaussianParameter _horizontalParam;
}
@property (nonatomic, assign) float verticalTexelSpacing;
@property (nonatomic, assign) float horizontalTexelSpacing;
@property (nonatomic, assign) CGSize lastSize;
@property (nonatomic, assign) BOOL texelSpacingMultiplierChanged;

@property (nonatomic, strong) id<MTLBuffer> verticalParamBuffer;
@property (nonatomic, strong) id<MTLBuffer> horizontalParamBuffer;
@end

@implementation MetalImageGaussianBlurFilter

- (instancetype)init {
    if (self = [super init]) {
        self.texelSpacingMultiplier = 2.0;
        self.blurRadiusInPixels = 4.0;
    }
    return self;
}

- (void)switchRenderPiplineWithBlurVertex:(NSString *)vertex fragment:(NSString *)fragment {
    NSError *error = nil;
    id<MTLLibrary> library = [[MetalImageDevice shared].device newLibraryWithSource:[NSString stringWithFormat:@"%@ \n %@", vertex, fragment] options:nil error:&error];
    if (error) {
        assert(!"高斯滤镜脚本编译失败");
        return ;
    }
    
    MTLRenderPipelineDescriptor *des = [[MTLRenderPipelineDescriptor alloc] init];
    des.vertexFunction = [library newFunctionWithName:@"gaussianVertex"];
    des.fragmentFunction = [library newFunctionWithName:@"gaussianFragment"];
    des.colorAttachments[0].pixelFormat = [MetalImageDevice shared].pixelFormat;
    
    self.target.pielineState = [[MetalImageDevice shared].device newRenderPipelineStateWithDescriptor:des error:&error];
    if (error) {
        assert(!"高斯滤镜管线创建失败");
        return ;
    }
}

#pragma mark -
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (resource.type != MetalImageResourceTypeImage) {
        [self send:resource withTime:time];
        return;
    }
    
    MetalImageTextureResource *textureResource = (MetalImageTextureResource *)resource;
    [textureResource.renderProcess commitRender];// 先把之前的提交了
    
    id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
    [commandBuffer enqueue];
    [self encodeToCommandBuffer:commandBuffer withResource:textureResource];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    [self send:textureResource withTime:time];
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageTextureResource *)resource {    
    // 目标大小变了
    CGSize targetSize = CGSizeEqualToSize(self.target.size, CGSizeZero) ? resource.renderProcess.targetSize : self.target.size;
    if (!CGSizeEqualToSize(_lastSize, targetSize) || _texelSpacingMultiplierChanged) {
        self->_verticalParam.texelWidthOffset = self.verticalTexelSpacing / targetSize.width;
        self->_verticalParam.texelHeightOffset = 0.0;
        
        self->_horizontalParam.texelWidthOffset = 0.0;
        self->_horizontalParam.texelHeightOffset = self.horizontalTexelSpacing / targetSize.height;
        _lastSize = targetSize;
        _verticalParamBuffer = nil;
        _horizontalParamBuffer = nil;
        _texelSpacingMultiplierChanged = NO;
    }
    
    @autoreleasepool {
        // 水平方向来一次
        _currentParam = _horizontalParam;
        MetalImageTexture *horizontalTargetTexture = [[MetalImageDevice shared].textureCache fetchTexture:targetSize
                                                                                              pixelFormat:resource.texture.metalTexture.pixelFormat];
        horizontalTargetTexture.orientation = resource.texture.orientation;
        self.target.renderPassDecriptor.colorAttachments[0].texture = horizontalTargetTexture.metalTexture;
        
        id<MTLRenderCommandEncoder> horizontalRenderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.target.renderPassDecriptor];
        [self renderToEncoder:horizontalRenderEncoder withResource:resource];
        [horizontalRenderEncoder endEncoding];
        [resource.renderProcess swapTexture:horizontalTargetTexture];
        
        // 垂直方向再来一次
        _currentParam = _verticalParam;
        MetalImageTexture *verticalTargetTexture = [[MetalImageDevice shared].textureCache fetchTexture:targetSize
                                                                                            pixelFormat:resource.texture.metalTexture.pixelFormat];
        verticalTargetTexture.orientation = resource.texture.orientation;
        self.target.renderPassDecriptor.colorAttachments[0].texture = verticalTargetTexture.metalTexture;
        
        id<MTLRenderCommandEncoder> verticalRenderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.target.renderPassDecriptor];
        [self renderToEncoder:verticalRenderEncoder withResource:resource];
        [verticalRenderEncoder endEncoding];
        [resource.renderProcess swapTexture:verticalTargetTexture];
    };
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];

#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Gaussian Draw"];
#endif
    if (@available(iOS 8.3, *)) {
        [renderEncoder setVertexBytes:&_currentParam length:sizeof(_currentParam) atIndex:2];
        [renderEncoder setFragmentBytes:&_currentParam length:sizeof(_currentParam) atIndex:0];
    } else {
        id <MTLBuffer> buffer = ((_currentParam.texelHeightOffset == _verticalParam.texelHeightOffset) && (_currentParam.texelWidthOffset == _verticalParam.texelWidthOffset)) ? self.verticalParamBuffer : self.horizontalParamBuffer;
        [renderEncoder setVertexBuffer:buffer offset:0 atIndex:2];
        [renderEncoder setFragmentBuffer:buffer offset:0 atIndex:0];
    }
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

#pragma mark - 属性设置
- (id<MTLBuffer>)horizontalParamBuffer {
    if (!_horizontalParamBuffer) {
        _horizontalParamBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_horizontalParam length:sizeof(_horizontalParam) options:0];
    }
    return _horizontalParamBuffer;
}

- (id<MTLBuffer>)verticalParamBuffer {
    if (!_verticalParamBuffer) {
        _verticalParamBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_verticalParam length:sizeof(_verticalParam) options:0];
    }
    return _verticalParamBuffer;
}

- (void)setTexelSpacingMultiplier:(float)texelSpacingMultiplier {
    if (_texelSpacingMultiplier != texelSpacingMultiplier) {
        _texelSpacingMultiplierChanged = YES;
        _texelSpacingMultiplier = texelSpacingMultiplier;
        _verticalTexelSpacing = _texelSpacingMultiplier;
        _horizontalTexelSpacing = _texelSpacingMultiplier;
    }
}

- (void)setBlurRadiusInPixels:(float)blurRadiusInPixels {
    if (round(blurRadiusInPixels) != _blurRadiusInPixels){
        _blurRadiusInPixels = round(blurRadiusInPixels);
        NSUInteger calculatedSampleRadius = 0;
        if (_blurRadiusInPixels >= 1) {
            CGFloat minimumWeightToFindEdgeOfSamplingArea = 1.0 / 256.0;
            calculatedSampleRadius = floor(sqrt(-2.0 * pow(_blurRadiusInPixels, 2.0) * log(minimumWeightToFindEdgeOfSamplingArea * sqrt(2.0 * M_PI * pow(_blurRadiusInPixels, 2.0)))));
            calculatedSampleRadius += calculatedSampleRadius % 2;
        }
        
        NSString *newGaussianBlurVertexShader = [[self class] vertexShaderForBlurOfRadius:calculatedSampleRadius sigma:_blurRadiusInPixels];
        NSString *newGaussianBlurFragmentShader = [[self class] fragmentShaderForBlurOfRadius:calculatedSampleRadius sigma:_blurRadiusInPixels];
        [self switchRenderPiplineWithBlurVertex:newGaussianBlurVertexShader fragment:newGaussianBlurFragmentShader];
    }
}

#pragma mark - 高斯模糊动态脚本生成
+ (NSString *)vertexShaderForBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma {
    if (blurRadius < 1) {
        return MetalImageGaussinDefaultVertex;
    }
    
    // 给sigma参数分配正太高斯权重
    GLfloat *standardGaussianWeights = (GLfloat *)calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));
        if (currentGaussianWeightIndex == 0) {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
     // 接下来，对这些权重进行归一化以防止在离散样本结束时高斯曲线的剪切降低亮度
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }
    
    // 根据这些权重，我们计算从中读取插值的偏移量
    NSUInteger numberOfOptimizedOffsets = MIN(blurRadius / 2 + (blurRadius % 2), 7);
    GLfloat *optimizedGaussianOffsets = (GLfloat *)calloc(numberOfOptimizedOffsets, sizeof(GLfloat));
    
    for (NSUInteger currentOptimizedOffset = 0; currentOptimizedOffset < numberOfOptimizedOffsets; currentOptimizedOffset++) {
        GLfloat firstWeight = standardGaussianWeights[currentOptimizedOffset * 2 + 1];
        GLfloat secondWeight = standardGaussianWeights[currentOptimizedOffset * 2 + 2];
        GLfloat optimizedWeight = firstWeight + secondWeight;
        optimizedGaussianOffsets[currentOptimizedOffset] = (firstWeight * (currentOptimizedOffset * 2 + 1) + secondWeight * (currentOptimizedOffset * 2 + 2)) / optimizedWeight;
    }

    NSMutableString *shaderString = [[NSMutableString alloc] init];
    [shaderString appendFormat:@"using namespace metal;\n"];
    [shaderString appendFormat:@"struct SingleInputVertexIO {\n"];
    [shaderString appendFormat:@"   float4 position [[position]];\n"];
    [shaderString appendFormat:@"   float2 textureCoordinate [[user(texturecoord)]];\n"];
    for (int i = 0; i < 1 + (numberOfOptimizedOffsets * 2); i++) {
        [shaderString appendFormat:@"   float2 blurCoordinates_%d;\n", i];
    }
    [shaderString appendFormat:@"};\n"];
    [shaderString appendFormat:@"struct GaussianUniformParameter {\n"];
    [shaderString appendFormat:@"   float texelWidthOffset;\n"];
    [shaderString appendFormat:@"   float texelHeightOffset;\n};\n\n"];
    [shaderString appendFormat:@"vertex SingleInputVertexIO gaussianVertex(device packed_float2 *position [[buffer(0)]],\n"];
    [shaderString appendFormat:@"                                          device packed_float2 *texturecoord [[buffer(1)]],\n"];
    [shaderString appendFormat:@"                                          constant GaussianUniformParameter &gaussianPara [[buffer(2)]],\n"];
    [shaderString appendFormat:@"                                          uint vid [[vertex_id]]) {\n"];
    [shaderString appendFormat:@"   SingleInputVertexIO outputVertices;\n"];
    [shaderString appendFormat:@"   outputVertices.position = float4(position[vid], 0, 1.0);\n"];
    [shaderString appendFormat:@"   outputVertices.textureCoordinate = texturecoord[vid];\n"];
    [shaderString appendFormat:@"   float2 singleStepOffset = float2(gaussianPara.texelWidthOffset, gaussianPara.texelHeightOffset);\n\n"];

    [shaderString appendString:@"   outputVertices.blurCoordinates_0 = texturecoord[vid];\n"];
    for (NSUInteger currentOptimizedOffset = 0; currentOptimizedOffset < numberOfOptimizedOffsets; currentOptimizedOffset++) {
        [shaderString appendFormat:@"   outputVertices.blurCoordinates_%lu = texturecoord[vid] + singleStepOffset * %f;\n", (unsigned long)((currentOptimizedOffset * 2) + 1), optimizedGaussianOffsets[currentOptimizedOffset]];
        [shaderString appendFormat:@"   outputVertices.blurCoordinates_%lu = texturecoord[vid] - singleStepOffset * %f;\n", (unsigned long)((currentOptimizedOffset * 2) + 2), optimizedGaussianOffsets[currentOptimizedOffset]];
    }
    [shaderString appendFormat:@"   return outputVertices;\n}\n"];
    
    free(optimizedGaussianOffsets);
    free(standardGaussianWeights);
    return shaderString;
}

+ (NSString *)fragmentShaderForBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma {
    if (blurRadius < 1) {
        return kMetalImageGaussinDefaultFragment;
    }
    
    // 给sigma参数分配正太高斯权重
    GLfloat *standardGaussianWeights = (GLfloat *)calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));
        if (currentGaussianWeightIndex == 0) {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        }
        else {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // 接下来，对这些权重进行归一化以防止在离散样本结束时高斯曲线的剪切降低亮度
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }
    
    // 根据这些权重，我们计算从中读取插值的偏移量
    NSUInteger numberOfOptimizedOffsets = MIN(blurRadius / 2 + (blurRadius % 2), 7);
    NSUInteger trueNumberOfOptimizedOffsets = blurRadius / 2 + (blurRadius % 2);
    
    NSMutableString *shaderString = [[NSMutableString alloc] init];
    [shaderString appendFormat:@"fragment half4 gaussianFragment(SingleInputVertexIO fragmentInput [[stage_in]],\n"];
    [shaderString appendFormat:@"                                constant GaussianUniformParameter &gaussianPara[[buffer(0)]],\n"];
    [shaderString appendFormat:@"                                texture2d<half> inputTexture [[texture(0)]]) {\n"];
    [shaderString appendFormat:@"   constexpr sampler quadSampler;\n"];
    [shaderString appendFormat:@"   half4 sum = half4(0.0);\n"];
    [shaderString appendFormat:@"   sum += inputTexture.sample(quadSampler, fragmentInput.blurCoordinates_0) * %f;\n", standardGaussianWeights[0]];
    for (NSUInteger currentBlurCoordinateIndex = 0; currentBlurCoordinateIndex < numberOfOptimizedOffsets; currentBlurCoordinateIndex++) {
        GLfloat firstWeight = standardGaussianWeights[currentBlurCoordinateIndex * 2 + 1];
        GLfloat secondWeight = standardGaussianWeights[currentBlurCoordinateIndex * 2 + 2];
        GLfloat optimizedWeight = firstWeight + secondWeight;
        
        [shaderString appendFormat:@"   sum += inputTexture.sample(quadSampler, fragmentInput.blurCoordinates_%lu) * %f;\n",
         (unsigned long)((currentBlurCoordinateIndex * 2) + 1), optimizedWeight];
        
        [shaderString appendFormat:@"   sum += inputTexture.sample(quadSampler, fragmentInput.blurCoordinates_%lu) * %f;\n",
         (unsigned long)((currentBlurCoordinateIndex * 2) + 2), optimizedWeight];
    }
    
    // 如果所需样本的数量超过了我们可以通过变化传入的数量，我们必须在片段着色器中进行相关的纹理读取
    if (trueNumberOfOptimizedOffsets > numberOfOptimizedOffsets) {
        [shaderString appendString:@"   float2 singleStepOffset = float2(gaussianPara.texelWidthOffset, gaussianPara.texelHeightOffset);\n"];
        for (NSUInteger currentOverlowTextureRead = numberOfOptimizedOffsets; currentOverlowTextureRead < trueNumberOfOptimizedOffsets; currentOverlowTextureRead++) {
            GLfloat firstWeight = standardGaussianWeights[currentOverlowTextureRead * 2 + 1];
            GLfloat secondWeight = standardGaussianWeights[currentOverlowTextureRead * 2 + 2];
            
            GLfloat optimizedWeight = firstWeight + secondWeight;
            GLfloat optimizedOffset = (firstWeight * (currentOverlowTextureRead * 2 + 1) + secondWeight * (currentOverlowTextureRead * 2 + 2)) / optimizedWeight;
            
            [shaderString appendFormat:@"sum += inputTexture.sample(quadSampler, fragmentInput.blurCoordinates_0 + singleStepOffset  * %f) * %f;\n", optimizedOffset, optimizedWeight];
            [shaderString appendFormat:@"sum += inputTexture.sample(quadSampler, fragmentInput.blurCoordinates_0 - singleStepOffset  * %f) * %f;\n", optimizedOffset, optimizedWeight];
        }
    }
    [shaderString appendFormat:@"   return sum;\n}\n"];
    
    free(standardGaussianWeights);
    return shaderString;
}

@end
