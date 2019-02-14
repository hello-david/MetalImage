//
//  MetalImageView.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import "MetalImageView.h"

@interface MetalImageView()
@property (nonatomic, strong) CAMetalLayer *metalLayer;
@property (nonatomic, strong) dispatch_queue_t displayQueue;
@property (nonatomic, strong) MetalImageTarget *renderTarget;
@end

@implementation MetalImageView
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commitInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commitInit];
    }
    return self;
}

- (void)commitInit {
    _metalLayer = [[CAMetalLayer alloc] init];
    _metalLayer.device = [MetalImageDevice shared].device;
    _metalLayer.pixelFormat = [MetalImageDevice shared].pixelFormat;
    _metalLayer.framebufferOnly = YES;
    _metalLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self.layer addSublayer:_metalLayer];
    
    _displayQueue = dispatch_queue_create("com.MetalImage.DisplayView", NULL);
    _renderTarget = [[MetalImageTarget alloc] initWithDefaultLibraryWithVertex:@"oneInputVertex"
                                                                        fragment:@"passthroughFragment"];
    _renderTarget.fillMode = kMetalImageContentModeScaleAspectFill;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.metalLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (MetalImageContentMode)fillMode {
    return _renderTarget.fillMode;
}

- (void)setFillMode:(MetalImageContentMode)fillMode {
    _renderTarget.fillMode = fillMode;
}

#pragma mark - Target Protocol
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (!resource || resource.type != kMetalImageResourceTypeImage) {
        return;
    }
    
    MetalImageTextureResource *textureResource = (MetalImageTextureResource *)resource;
    [textureResource endRenderProcess];
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_displayQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        @autoreleasepool {
            id <CAMetalDrawable> drawable = [strongSelf.metalLayer nextDrawable];
            if (drawable) {
                textureResource.renderPassDecriptor.colorAttachments[0].texture = [drawable texture];
                [strongSelf.renderTarget updateBufferIfNeed:textureResource.texture targetSize:strongSelf.metalLayer.frame.size];
                
                id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
                [commandBuffer enqueue];
                
                id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:textureResource.renderPassDecriptor];
                [strongSelf renderToEncoder:renderEncoder withResource:textureResource];
                [commandBuffer presentDrawable:drawable];
                [commandBuffer commit];
                
                [[MetalImageDevice shared].textureCache cacheTexture:textureResource.texture];
            }
        }
    });
}

#pragma mark - Render Process
- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Display Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:_renderTarget.pielineState];
    [renderEncoder setVertexBuffer:_renderTarget.position offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_renderTarget.textureCoord offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
    [renderEncoder endEncoding];
}

@end
