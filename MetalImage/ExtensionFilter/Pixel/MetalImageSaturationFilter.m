//
//  MetalImageSaturationFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageSaturationFilter.h"
@interface MetalImageSaturationFilter()
@property (nonatomic, strong) id<MTLBuffer> saturationBuffer;
@end

@implementation MetalImageSaturationFilter
- (instancetype)init {
    if (self = [super initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"saturationFragment" library:[MetalImageDevice shared].library]) {
        _saturation = 1.0;
    }
    return self;
}

- (id<MTLBuffer>)saturationBuffer {
    if (!_saturationBuffer) {
        _saturationBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_saturation length:sizeof(_saturation) options:0];
    }
    return _saturationBuffer;
}

- (void)setSaturation:(float)saturation {
    _saturation = saturation;
    _saturationBuffer = nil;
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Saturation Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.renderPielineState];
    [renderEncoder setVertexBuffer:resource.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.textureCoorBuffer offset:0 atIndex:1];
    if (@available(iOS 8.3, *)) {
        [renderEncoder setFragmentBytes:&_saturation length:sizeof(_saturation) atIndex:2];
    } else {
        [renderEncoder setFragmentBuffer:self.saturationBuffer offset:0 atIndex:2];
    }
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
