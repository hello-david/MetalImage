//
//  MetalImageContrastFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/3/24.
//

#import "MetalImageContrastFilter.h"

@implementation MetalImageContrastFilter
- (instancetype)init {
    self = [super initWithVertexFunction:kMetalImageDefaultVertex
                        fragmentFunction:@"contrastFragment"
                                 library:[MetalImageDevice shared].library];
    if (self) {
        _contrast = 1.0;
    }
    return self;
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageResource *)resource {
    if (resource.type != MetalImageResourceTypeImage) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Contrast Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBytes:&_contrast length:sizeof(_contrast) atIndex:2];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
