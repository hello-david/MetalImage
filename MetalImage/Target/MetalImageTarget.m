//
//  MetalImageTarget.m
//  MetalImage
//
//  Created by David.Dai on 2019/1/3.
//

#import "MetalImageTarget.h"
typedef struct {
    CGSize textureSize;
    CGSize targetSize;
    MetalImageOrientation textureOrientation;
    MetalImageContentMode fillMode;
} MetalImageBufferReuseInfo;

@interface MetalImageTarget()
@property (nonatomic, assign) MetalImageBufferReuseInfo bufferReuseInfo;
@end

@implementation MetalImageTarget

- (instancetype)initWithDefaultLibraryWithVertex:(NSString *)vertexFunctionName fragment:(NSString *)fragmentFunctionName {
    return [self initWithDefaultLibraryWithVertex:vertexFunctionName fragment:fragmentFunctionName enableBlend:NO];
}

- (instancetype)initWithDefaultLibraryWithVertex:(NSString *)vertexFunctionName
                                        fragment:(NSString *)fragmentFunctionName
                                     enableBlend:(BOOL)enableBlend {

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"MetalImageBundle" ofType:@"bundle"];
    NSString *defaultMetalFile = [bundlePath stringByAppendingPathComponent:@"default.metallib"];
    NSError *error = nil;
    id<MTLLibrary>library = [[MetalImageDevice shared].device newLibraryWithFile:defaultMetalFile error:&error];
    if (error) {
        assert(!"Create library failed");
    }
    
    return [self initWithVertexFunction:vertexFunctionName fragmentFunction:fragmentFunctionName library:library enableBlend:enableBlend];
}

- (instancetype)initWithVertexFunction:(NSString *)vertexFunction
                      fragmentFunction:(NSString *)fragmentFunction
                               library:(id<MTLLibrary>)library
                           enableBlend:(BOOL)enableBlend {
    if (self = [super init]) {
        NSError *error = nil;
        MTLRenderPipelineDescriptor *renderPipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDesc.vertexFunction = [library newFunctionWithName:vertexFunction];
        renderPipelineDesc.fragmentFunction = [library newFunctionWithName:fragmentFunction];
        renderPipelineDesc.colorAttachments[0].pixelFormat = [MetalImageDevice shared].pixelFormat;
        
        if (enableBlend) {
            // 结果色 = 源色 * 源因子 + 目标色 * 目标因子
            // 结果alpha = 源透明度 * 源因子 + 目标透明度 * 目标因子

            renderPipelineDesc.colorAttachments[0].blendingEnabled = YES;
            renderPipelineDesc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
            renderPipelineDesc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
            renderPipelineDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
            renderPipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
            renderPipelineDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
            renderPipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        }
        
        _pielineState = [[MetalImageDevice shared].device newRenderPipelineStateWithDescriptor:renderPipelineDesc error:&error];
        if (error) {
            assert(!"Create piplinstate failed");
        }
        
        _fillMode = MetalImageContentModeScaleToFill;
    }
    return self;
}

- (void)updateCoordinateIfNeed:(MetalImageTexture *)texture {
    BOOL textureSizeChange = !CGSizeEqualToSize(CGSizeMake(texture.width, texture.height), _bufferReuseInfo.textureSize);
    BOOL textureOritationChange = texture.orientation != _bufferReuseInfo.textureOrientation;
    BOOL targetSizeChange = !CGSizeEqualToSize(self.size, _bufferReuseInfo.targetSize);
    BOOL fillModeChange = _fillMode != _bufferReuseInfo.fillMode;
    
    if (!textureSizeChange && !textureOritationChange && !targetSizeChange && !fillModeChange) {
        return;
    }
    
    _bufferReuseInfo.fillMode = _fillMode;
    _bufferReuseInfo.targetSize = self.size;
    _bufferReuseInfo.textureOrientation = texture.orientation;
    _bufferReuseInfo.textureSize = CGSizeMake(texture.width, texture.height);
    
    // 将纹理旋转到正上方向再绘制到目标纹理中
    MetalImageCoordinate position = [texture texturePositionToSize:self.size contentMode:_fillMode];
    MetalImageCoordinate textureCoor = [texture textureCoordinatesToOrientation:MetalImagePortrait];
    
    _position = [[MetalImageDevice shared].device newBufferWithBytes:&position length:sizeof(position) options:0];
    _textureCoord = [[MetalImageDevice shared].device newBufferWithBytes:&textureCoor length:sizeof(textureCoor) options:0];
}

- (MTLRenderPassDescriptor *)renderPassDecriptor {
    if (!_renderPassDecriptor) {
        _renderPassDecriptor = [[MTLRenderPassDescriptor alloc] init];
        _renderPassDecriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderPassDecriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _renderPassDecriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1);
    }
    return _renderPassDecriptor;
}
@end
