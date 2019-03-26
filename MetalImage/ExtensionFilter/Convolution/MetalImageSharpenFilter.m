//
//  MetalImageSharpenFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageSharpenFilter.h"
typedef struct MetalImageSharpenFilterArg {
    float imageWidthFactor;
    float imageHeightFactor;
    float sharpenss;
} MetalImageSharpenFilterArg;

@interface MetalImageSharpenFilter()
@property (nonatomic, strong) id<MTLBuffer> sharpenBuffer;
@property (nonatomic, assign) MetalImageSharpenFilterArg sharpenArg;
@end

@implementation MetalImageSharpenFilter
- (instancetype)init {
    if (self = [super initWithVertexFunction:@"sharpenVertex" fragmentFunction:@"sharpenFragment" library:[MetalImageDevice shared].library]) {
        _sharpenArg.sharpenss = 0.0;
        _sharpenArg.imageHeightFactor = 0.0;// 单位像素高
        _sharpenArg.imageWidthFactor = 0.0;// 单位像素宽
    }
    return self;
}

- (id<MTLBuffer>)sharpenBuffer {
    if (!_sharpenBuffer) {
        _sharpenBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&_sharpenArg length:sizeof(_sharpenArg) options:0];
    }
    return _sharpenBuffer;
}

- (void)setSharpness:(float)sharpness {
    _sharpness = sharpness;
    _sharpenArg.sharpenss = sharpness;
    _sharpenBuffer = nil;
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
    // 目标大小变了
    if ((1.0 / resource.renderSize.width != _sharpenArg.imageWidthFactor) || (1.0 / resource.renderSize.height != _sharpenArg.imageHeightFactor)) {
        _sharpenArg.imageWidthFactor = 1.0 / resource.renderSize.width;
        _sharpenArg.imageHeightFactor = 1.0 / resource.renderSize.height;
        _sharpenBuffer = nil;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Sharpen Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.renderPielineState];
    [renderEncoder setVertexBuffer:resource.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.textureCoorBuffer offset:0 atIndex:1];
    
    if (@available(iOS 8.3, *)) {
        [renderEncoder setVertexBytes:&_sharpenArg length:sizeof(_sharpenArg) atIndex:2];
    } else {
        [renderEncoder setVertexBuffer:self.sharpenBuffer offset:0 atIndex:2];
    }
    
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

@end
