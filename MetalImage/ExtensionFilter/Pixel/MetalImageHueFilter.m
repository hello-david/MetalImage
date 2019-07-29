//
//  MetalImageHueFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/3/25.
//

#import "MetalImageHueFilter.h"

@implementation MetalImageHueFilter
- (instancetype)init {
    self = [super initWithVertexFunction:kMetalImageDefaultVertex
                        fragmentFunction:@"hueFragment"
                                 library:[MetalImageDevice shared].library];
    if (self) {
        _hue = 0.0;
    }
    return self;
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Hue Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBytes:&_hue length:sizeof(_hue) atIndex:2];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
