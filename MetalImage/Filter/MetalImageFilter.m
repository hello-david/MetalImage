//
//  MetalImageFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import "MetalImageFilter.h"
@interface MetalImageFilter()
@property (nonatomic, strong) MetalImageSource *source;
@end

@implementation MetalImageFilter
- (instancetype)init {
    return [self initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"passthroughFragment" library:[MetalImageDevice shared].library];
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunction fragmentFunction:(NSString *)fragmentFunction library:(id<MTLLibrary>)library {
    if (self = [super init]) {
        [self commonInitWithVertexFunction:vertexFunction
                          fragmentFunction:fragmentFunction
                                   library:library];
        
        _source = [[MetalImageSource alloc] init];
    }
    return self;
}

- (void)commonInitWithVertexFunction:(NSString *)vertexFunction fragmentFunction:(NSString *)fragmentFunction library:(id<MTLLibrary>)library {
    MTLRenderPipelineDescriptor *des = [[MTLRenderPipelineDescriptor alloc] init];
    des.vertexFunction = [library newFunctionWithName:vertexFunction];
    des.fragmentFunction = [library newFunctionWithName:fragmentFunction];
    des.colorAttachments[0].pixelFormat = [MetalImageDevice shared].pixelFormat;
    
    NSError *error = nil;
    _renderPielineState = [[MetalImageDevice shared].device newRenderPipelineStateWithDescriptor:des error:&error];
    if (error) {
        assert(!"Create piplinstate failed");
    }
}

#pragma mark - Target Protocol
/**
 *  内部渲染处理不应该切换线程，需要并发渲染使用MTLParallelRenderCommandEncoder实现
 *  默认实现draw-call后交换纹理指针传给下一级
 */
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (resource.type != MetalImageResourceTypeImage) {
        [self send:resource withTime:time];
        return;
    }
    
    MetalImageTextureResource *textureResource = (MetalImageTextureResource *)resource;
    [textureResource.renderProcess startRender:^(id<MTLRenderCommandEncoder> renderEncoder) {
        [self renderToEncoder:renderEncoder withResource:textureResource];
    } completion:^{
        if (!self.source.haveTarget) {
            [textureResource.renderProcess endRender];
            return;
        }
        [self send:resource withTime:time];
    }];
}

#pragma mark - Render Process
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageTextureResource *)resource {
    CGSize targetSize = CGSizeEqualToSize(_targetSize, CGSizeZero) ? resource.renderProcess.renderSize : _targetSize;
    MetalImageTexture *targetTexture = [[MetalImageDevice shared].textureCache fetchTexture:targetSize
                                                                                pixelFormat:resource.texture.metalTexture.pixelFormat];
    targetTexture.orientation = resource.texture.orientation;
    resource.renderProcess.renderPassDecriptor.colorAttachments[0].texture = targetTexture.metalTexture;
    
    // 实现一个renderEncoder流程(可能有多个Draw-Call)
    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:resource.renderProcess.renderPassDecriptor];
        [self renderToEncoder:renderEncoder withResource:resource];
        [renderEncoder endEncoding];
        [resource.renderProcess swapTexture:targetTexture];
    }
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Passthrough Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.renderPielineState];
    [renderEncoder setVertexBuffer:resource.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

#pragma mark - Render Protocol
-(void)renderToResource:(MetalImageTextureResource *)resource {
    id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
    [commandBuffer enqueue];
    [self encodeToCommandBuffer:commandBuffer withResource:resource];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

#pragma mark - Source Protocol
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    [self.source send:resource withTime:time];
}

- (void)addTarget:(id<MetalImageTarget>)target {
    [self.source addTarget:target];
}

- (void)removeTarget:(id<MetalImageTarget>)target {
    [self.source removeTarget:target];
}

- (void)removeAllTarget {
    [self.source removeAllTarget];
}
@end
