//
//  MetalImageLookUpTableFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/7/4.
//

#import "MetalImageLookUpTableFilter.h"

@interface MetalImageLookUpTableFilter()
@property (nonatomic, strong) id<MTLTexture> lookUpTableTexture;
@property (nonatomic, assign) UInt8 sampleStep;
@end

@implementation MetalImageLookUpTableFilter

- (instancetype)initWithLutTexture:(id<MTLTexture>)lutTexture sampleStep:(UInt8)sampleStep {
    self = [super initWithVertexFunction:kMetalImageDefaultVertex
                        fragmentFunction:@"lookUpTableFragment"
                                 library:[MetalImageDevice shared].library];
    if (self) {
        _lookUpTableTexture = lutTexture;
        _sampleStep = sampleStep;
        _intensity = 0.0;
    }
    return self;
}

- (void)replaceLutTexture:(id<MTLTexture>)lutTexture sampleStep:(UInt8)sampleStep {
    _lookUpTableTexture = lutTexture;
    _sampleStep = sampleStep;
}

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(nonnull MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"LUT Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:self.target.pielineState];
    [renderEncoder setVertexBuffer:resource.renderProcess.positionBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:resource.renderProcess.textureCoorBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentBytes:&_sampleStep length:sizeof(_sampleStep) atIndex:2];
    [renderEncoder setFragmentBytes:&_intensity length:sizeof(_intensity) atIndex:3];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder setFragmentTexture:_lookUpTableTexture atIndex:1];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

@end
