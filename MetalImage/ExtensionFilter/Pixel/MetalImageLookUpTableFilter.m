//
//  MetalImageLookUpTableFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/7/4.
//

#import "MetalImageLookUpTableFilter.h"

typedef struct {
    unsigned int maxColorValue;   // lut每个分量的有多少种颜色
    unsigned int latticeCount;    // 每排晶格数量
    unsigned int width;           // lut宽度
    unsigned int height;          // lut高度
} MetalImageLutInfo;

@interface MetalImageLookUpTableFilter()
@property (nonatomic, strong) id<MTLTexture> lookUpTableTexture;
@property (nonatomic, assign) MetalImageLutInfo lutInfo;
@property (nonatomic, assign) MetalImageLUTFilterType type;
@end

@implementation MetalImageLookUpTableFilter

- (instancetype)initWithLutTexture:(id<MTLTexture>)lutTexture type:(MetalImageLUTFilterType)type {
    self = [super initWithVertexFunction:kMetalImageDefaultVertex
                        fragmentFunction:@"lookUpTableFragment"
                                 library:[MetalImageDevice shared].library];
    if (self) {
        [self replaceLutTexture:lutTexture type:type];
        _intensity = 0.0;
    }
    return self;
}

- (void)replaceLutTexture:(id<MTLTexture>)lutTexture type:(MetalImageLUTFilterType)type {
    _lookUpTableTexture = lutTexture;
    _type = type;

    unsigned int latticeCount, maxColorValue;
    switch (type) {
    case MetalImageLUTFilterType8_8:
        latticeCount = 8;
        break;
    case MetalImageLUTFilterType4_4:
        latticeCount = 4;
        break;
    default:
        latticeCount = 8;
        break;
    }

    maxColorValue = (unsigned int)lutTexture.width / latticeCount - 1;
    _lutInfo = (MetalImageLutInfo){
        maxColorValue,
        latticeCount,
        (unsigned int)lutTexture.width,
        (unsigned int)lutTexture.height
    };
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
    [renderEncoder setFragmentBytes:&_intensity length:sizeof(_intensity) atIndex:2];
    [renderEncoder setFragmentBytes:&_lutInfo length:sizeof(_lutInfo) atIndex:3];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder setFragmentTexture:_lookUpTableTexture atIndex:1];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

@end
