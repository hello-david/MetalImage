//
//  MetalImageSaturationFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageSaturationFilter.h"
@implementation MetalImageSaturationFilter
- (instancetype)init {
    self = [super initWithVertexFunction:kMetalImageDefaultVertex
                        fragmentFunction:@"saturationFragment"
                                 library:[MetalImageDevice shared].library];
    if (self) {
        _saturation = 1.0;
    }
    return self;
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(nonnull MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Saturation Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBytes:&_saturation length:sizeof(_saturation) atIndex:2];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
