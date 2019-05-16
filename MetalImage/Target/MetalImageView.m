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
    [textureResource.renderProcess endRender];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_displayQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        @autoreleasepool {
            id <CAMetalDrawable> drawable = [strongSelf.metalLayer nextDrawable];
            if (drawable) {
                MTLClearColor color = [strongSelf getMTLbackgroundColor];
                textureResource.renderProcess.renderPassDecriptor.colorAttachments[0].texture = [drawable texture];
                textureResource.renderProcess.renderPassDecriptor.colorAttachments[0].clearColor = color;
                
                if (strongSelf.metalLayer.opaque && color.alpha != 1.0) {
                    strongSelf.metalLayer.opaque = NO;
                } else if (color.alpha == 1.0) {
                    strongSelf.metalLayer.opaque = YES;
                }
                
                [strongSelf.renderTarget updateBufferIfNeed:textureResource.texture targetSize:strongSelf.metalLayer.frame.size];
                
                id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
                [commandBuffer enqueue];
                
                id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:textureResource.renderProcess.renderPassDecriptor];
                [strongSelf renderToEncoder:renderEncoder withResource:textureResource];
                [commandBuffer presentDrawable:drawable];
                [commandBuffer commit];
                
                [[MetalImageDevice shared].textureCache cacheTexture:textureResource.texture];
            }
        }
    });
}

- (MTLClearColor)getMTLbackgroundColor {
    UIColor *backgroundColor = self.metalBackgroundColor;
    
    CGFloat components[4];
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char resultingPixel[4];
    CGContextRef context = CGBitmapContextCreate(&resultingPixel, 1, 1, 8, 4, rgbColorSpace, kCGImageAlphaNoneSkipLast);
    CGContextSetFillColorWithColor(context, [backgroundColor CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
    for (int component = 0; component < 4; component++) {
        components[component] = resultingPixel[component] / 255.0f;
    }
    
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
