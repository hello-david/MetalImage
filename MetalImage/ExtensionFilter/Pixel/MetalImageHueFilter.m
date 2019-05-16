//
//  MetalImageHueFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/3/25.
//

#import "MetalImageHueFilter.h"

@interface MetalImageHueFilter()
@property (nonatomic, strong) id<MTLBuffer> hueBuffer;
@end

@implementation MetalImageHueFilter
- (instancetype)init {
    if (self = [super initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"hueFragment" library:[MetalImageDevice shared].library]) {
        _hue = 0.0;
    }
    return self;
}

- (id<MTLBuffer>)hueBuffer {
    if (!_hueBuffer) {
        _hueBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_hue length:sizeof(_hue) options:0];
    }
    return _hueBuffer;
}

- (void)setHue:(float)hue {
    _hue = hue;
    _hueBuffer = nil;
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Hue Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    if (@available(iOS 8.3, *)) {
        [renderEncoder setFragmentBytes:&_hue length:sizeof(_hue) atIndex:2];
    } else {
        [renderEncoder setFragmentBuffer:self.hueBuffer offset:0 atIndex:2];
    }
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
