//
//  MetalImageTarget.m
//  MetalImage
//
//  Created by David.Dai on 2019/1/3.
//

#import "MetalImageTarget.h"

@implementation MetalImageTarget

- (instancetype)initWithDefaultLibraryWithVertex:(NSString *)vertexFunctionName
                                        fragment:(NSString *)fragmentFunctionName {
    if (self = [super init]) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"MetalImageBundle" ofType:@"bundle"];
        NSString *defaultMetalFile = [bundlePath stringByAppendingPathComponent:@"default.metallib"];
        NSError *error = nil;
        id<MTLLibrary>library = [[MetalImageDevice shared].device newLibraryWithFile:defaultMetalFile error:&error];
        if (error) {
            assert(!"Create library failed");
        }
        
        MTLRenderPipelineDescriptor *des = [[MTLRenderPipelineDescriptor alloc] init];
        des.vertexFunction = [library newFunctionWithName:vertexFunctionName];
        des.fragmentFunction = [library newFunctionWithName:fragmentFunctionName];
        des.colorAttachments[0].pixelFormat = [MetalImageDevice shared].pixelFormat;
        
        _pielineState = [[MetalImageDevice shared].device newRenderPipelineStateWithDescriptor:des error:&error];
        if (error) {
            assert(!"Create piplinstate failed");
        }
        
        _fillMode = kMetalImageContentModeScaleToFill;
    }
    return self;
}

- (void)updateBufferIfNeed:(MetalImageTexture *)texture targetSize:(CGSize)targetSize {
    BOOL textureSizeChange = !CGSizeEqualToSize(CGSizeMake(texture.width, texture.height), _bufferReuseInfo.textureSize);
    BOOL textureOritationChange = texture.orientation != _bufferReuseInfo.textureOrientation;
    BOOL targetSizeChange = !CGSizeEqualToSize(targetSize, _bufferReuseInfo.targetSize);
    BOOL fillModeChange = _fillMode != _bufferReuseInfo.fillMode;
    
    if (!textureSizeChange && !textureOritationChange && !targetSizeChange && !fillModeChange) {
        return;
    }
    
    _bufferReuseInfo.fillMode = _fillMode;
    _bufferReuseInfo.targetSize = targetSize;
    _bufferReuseInfo.textureOrientation = texture.orientation;
    _bufferReuseInfo.textureSize = CGSizeMake(texture.width, texture.height);
    
    // 将纹理旋转到正上方向再绘制到目标纹理中
    MetalImageCoordinate position = [texture texturePositionToSize:targetSize contentMode:_fillMode];
    MetalImageCoordinate textureCoor = [texture textureCoordinatesToOrientation:kMetalImagePortrait];
    
    _position = [[MetalImageDevice shared].device newBufferWithBytes:&position length:sizeof(position) options:0];
    _textureCoord = [[MetalImageDevice shared].device newBufferWithBytes:&textureCoor length:sizeof(textureCoor) options:0];
}
@end