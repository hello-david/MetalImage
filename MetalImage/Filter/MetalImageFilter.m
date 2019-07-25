//
//  MetalImageFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import "MetalImageFilter.h"
@interface MetalImageFilter()
@property (nonatomic, strong) MetalImageSource *source;
@property (nonatomic, strong) MetalImageTarget *target;
@end

@implementation MetalImageFilter
- (instancetype)init {
    return [self initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"passthroughFragment" library:[MetalImageDevice shared].library];
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunction
                      fragmentFunction:(NSString *)fragmentFunction
                               library:(id<MTLLibrary>)library {
    if (self = [super init]) {
        _target = [[MetalImageTarget alloc] initWithVertexFunction:vertexFunction
                                                  fragmentFunction:fragmentFunction
                                                           library:library
                                                       enableBlend:NO];
        _source = [[MetalImageSource alloc] init];
    }
    return self;
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
    
    if (self.chainProcessHandle) {
        self.chainProcessHandle(YES, resource, self);
    }
    
    if ([self supportProcessRenderCommandEncoderOnly]) {
        __weak typeof(self) weakSelf = self;
        __weak typeof(resource) weakResource = resource;
        [resource.renderProcess addRenderProcess:^(id<MTLRenderCommandEncoder> renderEncoder) {
            [weakSelf renderToCommandEncoder:renderEncoder withResource:weakResource];
        }];
    } else {
        [resource.renderProcess commitRender];// 先把之前的提交了
        [self renderToResource:resource];
    }
    
    if (!self.source.haveTarget) {
        [resource.renderProcess commitRender];
        return;
    }
    
    if (self.chainProcessHandle) {
        self.chainProcessHandle(NO, resource, self);
    }
    [self send:resource withTime:time];
}

#pragma mark - Render Process
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
    CGSize targetSize = CGSizeEqualToSize(self.target.size, CGSizeZero) ? resource.texture.size : self.target.size;
    MetalImageTexture *targetTexture = [[MetalImageDevice shared].textureCache fetchTexture:targetSize
                                                                                pixelFormat:resource.texture.metalTexture.pixelFormat];
    targetTexture.orientation = resource.texture.orientation;
    self.target.renderPassDecriptor.colorAttachments[0].texture = targetTexture.metalTexture;
    
    // 实现一个renderEncoder流程(可能有多个Draw-Call)
    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:self.target.renderPassDecriptor];
        [self renderToCommandEncoder:renderEncoder withResource:resource];
        [renderEncoder endEncoding];
        [resource.renderProcess swapTexture:targetTexture];
    }
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Passthrough Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

#pragma mark - Render Protocol
-(void)renderToResource:(MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
    id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
    [commandBuffer enqueue];
    [self encodeToCommandBuffer:commandBuffer withResource:resource];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

- (BOOL)supportProcessRenderCommandEncoderOnly {
    return YES;
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
