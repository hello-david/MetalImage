//
//  MetalImageLuminanceFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageLuminanceFilter.h"

@implementation MetalImageLuminanceFilter
- (instancetype)init {
    if (self = [super initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"luminanceRangeFragment" library:[MetalImageDevice shared].library]) {
        _rangeReductionFactor = 0.0;
    }
    return self;
}

- (void)setRangeReductionFactor:(float)rangeReductionFactor {
    _rangeReductionFactor = rangeReductionFactor;
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(nonnull MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Luminance Range Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBytes:&_rangeReductionFactor length:sizeof(_rangeReductionFactor) atIndex:2];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
