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
@property (nonatomic, assign) MetalImageSharpenFilterArg sharpenArg;
@end

@implementation MetalImageSharpenFilter
- (instancetype)init {
    self = [super initWithVertexFunction:@"sharpenVertex"
                        fragmentFunction:@"sharpenFragment"
                                 library:[MetalImageDevice shared].library];
    if (self) {
        _sharpenArg.sharpenss = 0.0;
        _sharpenArg.imageHeightFactor = 0.0;// 单位像素高
        _sharpenArg.imageWidthFactor = 0.0;// 单位像素宽
    }
    return self;
}

- (void)setSharpness:(float)sharpness {
    _sharpness = sharpness;
    _sharpenArg.sharpenss = sharpness;
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(nonnull MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
    // 目标大小变了
    if ((1.0 / resource.renderProcess.targetSize.width != _sharpenArg.imageWidthFactor) || (1.0 / resource.renderProcess.targetSize.height != _sharpenArg.imageHeightFactor)) {
        _sharpenArg.imageWidthFactor = 1.0 / resource.renderProcess.targetSize.width;
        _sharpenArg.imageHeightFactor = 1.0 / resource.renderProcess.targetSize.height;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"Sharpen Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setVertexBytes:&_sharpenArg length:sizeof(_sharpenArg) atIndex:2];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

@end
