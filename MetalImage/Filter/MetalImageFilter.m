//
//  MetalImageFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import "MetalImageFilter.h"
@interface MetalImageFilter()
@property (nonatomic, assign) CGSize renderSize;
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
    
    _source = [[MetalImageSource alloc] init];
}

#pragma mark - Target Protocol
/**
 *  内部渲染处理不应该切换线程，需要并发渲染使用MTLParallelRenderCommandEncoder实现
 */
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (resource.type != kMetalImageResourceTypeImage) {
        [self send:resource withTime:time];
        return;
    }
    
    MetalImageTextureResource *textureResource = (MetalImageTextureResource *)resource;
    if (!CGSizeEqualToSize(_renderSize, CGSizeZero)) {
        [textureResource setRenderSize:_renderSize];
    }
    
    [textureResource startRenderProcess:^(id<MTLRenderCommandEncoder> renderEncoder) {
        [self renderToEncoder:renderEncoder withResource:textureResource];
    } completion:^{
        if (!self.source.haveTarget) {
            [textureResource endRenderProcess];
            return;
        }
        [self send:resource withTime:time];
    }];
}

#pragma mark - Render Process
- (void)setRenderSize:(CGSize)renderSize {
    _renderSize = renderSize;
}

- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageTextureResource *)resource {
    CGSize renderSize = CGSizeEqualToSize(_renderSize, CGSizeZero) ? resource.texture.size : _renderSize;
    MetalImageTexture *processTexture = [[MetalImageDevice shared].textureCache fetchTexture:renderSize
                                                                                     pixelFormat:resource.texture.metalTexture.pixelFormat];
    processTexture.orientation = resource.texture.orientation;
    resource.renderPassDecriptor.colorAttachments[0].texture = processTexture.metalTexture;
    
    // 渲染Draw-Call
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:resource.renderPassDecriptor];
    [self renderToEncoder:renderEncoder withResource:resource];
    [renderEncoder endEncoding];
    [resource swapTexture:processTexture];
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

#pragma mark - Source Protocol
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    [self.source send:resource withTime:time];
}

- (void)setTarget:(id<MetalImageTarget>)target {
    [self.source setTarget:target];
}

- (void)addAsyncTarget:(id<MetalImageTarget>)target {
    [self.source addAsyncTarget:target];
}

- (void)removeTarget:(id<MetalImageTarget>)target {
    [self.source removeTarget:target];
}

- (void)removeAllTarget {
    [self.source removeAllTarget];
}
@end
