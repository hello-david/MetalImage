//
//  MetalImageContrastFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/3/24.
//

#import "MetalImageContrastFilter.h"

@interface MetalImageContrastFilter()
@property (nonatomic, strong) id<MTLBuffer> contrastBuffer;
@end

@implementation MetalImageContrastFilter
- (instancetype)init {
    if (self = [super initWithVertexFunction:@"oneInputVertex" fragmentFunction:@"contrastFragment" library:[MetalImageDevice shared].library]) {
        _contrast = 1.0;
    }
    return self;
}

- (id<MTLBuffer>)contrastBuffer {
    if (!_contrastBuffer) {
        _contrastBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_contrast length:sizeof(_contrast) options:0];
    }
    return _contrastBuffer;
}

- (void)setContrast:(float)contrast {
    _contrast = contrast;
    _contrastBuffer = nil;
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Contrast Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    if (@available(iOS 8.3, *)) {
        [renderEncoder setFragmentBytes:&_contrast length:sizeof(_contrast) atIndex:2];
    } else {
        [renderEncoder setFragmentBuffer:self.contrastBuffer offset:0 atIndex:2];
    }
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
