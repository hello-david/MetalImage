//
//  MetalImageLuminanceFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageLuminanceFilter.h"

@interface MetalImageLuminanceFilter()
@property (nonatomic, strong) id<MTLBuffer> rangeReductionBuffer;
@end

@implementation MetalImageLuminanceFilter
- (instancetype)init {
    if (self = [super initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"luminanceRangeFragment" library:[MetalImageDevice shared].library]) {
        _rangeReductionFactor = 0.0;
    }
    return self;
}

- (id<MTLBuffer>)rangeReductionBuffer {
    if (!_rangeReductionBuffer) {
        _rangeReductionBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_rangeReductionFactor length:sizeof(_rangeReductionFactor) options:0];
    }
    return _rangeReductionBuffer;
}

- (void)setRangeReductionFactor:(float)rangeReductionFactor {
    _rangeReductionFactor = rangeReductionFactor;
    _rangeReductionBuffer = nil;
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Luminance Range Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    if (@available(iOS 8.3, *)) {
        [renderEncoder setFragmentBytes:&_rangeReductionFactor length:sizeof(_rangeReductionFactor) atIndex:2];
    } else {
        [renderEncoder setFragmentBuffer:self.rangeReductionBuffer offset:0 atIndex:2];
    }
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
