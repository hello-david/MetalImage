//
//  MetalImageCropFilter.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageCropFilter.h"

@interface MetalImageCropFilter()
@property (nonatomic, strong) id<MTLBuffer> cropTextureCoord;
@end

@implementation MetalImageCropFilter

- (instancetype)initWithCropRegin:(CGRect)cropRegion {
    self = [super initWithVertexFunction:kMetalImageDefaultVertex
                        fragmentFunction:kMetalImageDefaultFragment
                                 library:[MetalImageDevice shared].library];
    if (self) {
        self.cropRegion = cropRegion;
    }
    return self;
}

- (void)setCropRegion:(CGRect)cropRegion {
    if (CGRectEqualToRect(cropRegion, _cropRegion)) {
        return;
    }
    _cropRegion = cropRegion;
    _cropTextureCoord = nil;
}

- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (resource.type != MetalImageResourceTypeImage) {
        [self send:resource withTime:time];
        return;
    }
    
    float width = CGRectGetWidth(_cropRegion) > resource.texture.width ? resource.texture.width : CGRectGetWidth(_cropRegion);
    float height = CGRectGetHeight(_cropRegion) > resource.texture.height ? resource.texture.height : CGRectGetHeight(_cropRegion);
    resource.renderProcess.targetSize = CGSizeMake(width, height);
    
    [super receive:resource withTime:time];
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(nonnull MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Crop Draw"];
#endif
    
    if (!_cropTextureCoord) {
        float x = _cropRegion.origin.x / resource.texture.width;
        float y = _cropRegion.origin.y / resource.texture.height;
        float width = _cropRegion.size.width / resource.texture.width;
        float height = _cropRegion.size.height / resource.texture.height;
        
        x = x > 1.0 ? 1.0 : x;
        y = y > 1.0 ? 1.0 : y;
        width = width > 1.0 ? 1.0 : width;
        height = height > 1.0 ? 1.0 : height;
        
        MetalImageCoordinate textureCoor;
        float leftX = x;
        float topY = 1.0 - y;
        float rightX = (x + width > 1.0) ? 1.0 : x + width;
        float bottomY = (1.0 - y - height < 0.0) ? 0.0 : 1.0 - y - height;
    
        textureCoor.topLeftX = leftX;
        textureCoor.topLeftY = topY;
        textureCoor.topRightX = rightX;
        textureCoor.topRightY = topY;
        textureCoor.bottomLeftX = leftX;
        textureCoor.bottomLeftY = bottomY;
        textureCoor.bottomRightX = rightX;
        textureCoor.bottomRightY = bottomY;
        
        _cropTextureCoord = [[MetalImageDevice shared].device newBufferWithBytes:&textureCoor length:sizeof(textureCoor) options:0];
    }
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_cropTextureCoord offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}
@end
