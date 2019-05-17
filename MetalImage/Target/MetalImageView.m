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
@property (nonatomic, strong) UIColor *metalBackgroundColor;
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
    _renderTarget.fillMode = MetalImageContentModeScaleAspectFill;
    _renderTarget.size = self.metalLayer.frame.size;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.metalLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    if (!CGSizeEqualToSize(self.renderTarget.size, self.metalLayer.frame.size)) {
        self.renderTarget.size = self.metalLayer.frame.size;
    }
}

- (MetalImageContentMode)fillMode {
    return _renderTarget.fillMode;
}

- (void)setFillMode:(MetalImageContentMode)fillMode {
    _renderTarget.fillMode = fillMode;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.metalBackgroundColor = backgroundColor;
}

#pragma mark - Target Protocol
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (!resource || resource.type != MetalImageResourceTypeImage) {
        return;
    }
    
    MetalImageTextureResource *textureResource = (MetalImageTextureResource *)resource;
    [textureResource.renderProcess commitRender];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.displayQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        @autoreleasepool {
            id <CAMetalDrawable> drawable = [strongSelf.metalLayer nextDrawable];
            if (drawable) {
                // View的Alpha使用layer的opaque实现而非开启这个Pieline的Blend
                MTLClearColor color = [strongSelf getMTLbackgroundColor];
                if (strongSelf.metalLayer.opaque && color.alpha != 1.0) {
                    strongSelf.metalLayer.opaque = NO;
                } else if (!strongSelf.metalLayer.opaque && color.alpha == 1.0) {
                    strongSelf.metalLayer.opaque = YES;
                }
                
                strongSelf.renderTarget.renderPassDecriptor.colorAttachments[0].texture = [drawable texture];
                strongSelf.renderTarget.renderPassDecriptor.colorAttachments[0].clearColor = color;
                [strongSelf.renderTarget updateCoordinateIfNeed:textureResource.texture];// 调整输入纹理绘制到目标纹理时的比例和方向
                
                id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
                [commandBuffer enqueue];
                id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:strongSelf.renderTarget.renderPassDecriptor];
                [strongSelf renderToEncoder:renderEncoder withResource:textureResource];
                [commandBuffer presentDrawable:drawable];
                [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull buffer) {
                    [[MetalImageDevice shared].textureCache cacheTexture:textureResource.texture];
                }];
                [commandBuffer commit];
            }
        }
    });
}

- (MTLClearColor)getMTLbackgroundColor {
    CGFloat components[4];
    [self.metalBackgroundColor getRed:components green:components + 1 blue:components + 2 alpha:components + 3];
    return MTLClearColorMake(components[0], components[1], components[2], components[3]);
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
