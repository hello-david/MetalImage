//
//  MetalImageTextureResource.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageTextureResource.h"

@interface MetalImageTextureResource ()
@property (nonatomic, strong) MetalImageRenderProcess *renderProcess;
@end

@implementation MetalImageTextureResource
- (instancetype)init {
    if (self = [super init]) {
        self.type = MetalImageResourceTypeImage;
    }
    return self;
}

- (instancetype)initWithTexture:(MetalImageTexture *)texture {
    if (self = [super init]) {
        self.type = MetalImageResourceTypeImage;
        self.renderProcess = [[MetalImageRenderProcess alloc] initWithTexture:texture];
    }
    return self;
}

- (MetalImageTexture *)texture {
    return self.renderProcess.texture;
}

- (MetalImageResource *)newResourceFromSelf {
    // 拷贝之前先提交之前的渲染
    [self.renderProcess endRender];
    
    // 拷贝当前的纹理
    __block MetalImageTextureResource *newResource = nil;
    @autoreleasepool {
        MetalImageTexture *copyTexture = [[MetalImageDevice shared].textureCache fetchTexture:self.texture.size
                                                                                  pixelFormat:self.texture.metalTexture.pixelFormat];
        copyTexture.orientation = self.texture.orientation;
        newResource = [[MetalImageTextureResource alloc] initWithTexture:copyTexture];
        [copyTexture replaceTexture:self.texture.metalTexture];
    }
    
    return newResource;
}

#pragma mark - Custom Acessors
- (id<MTLBuffer>)positionBuffer {
    if (!_positionBuffer) {
        // 默认不做比例调整
        MetalImageCoordinate position = [self.texture texturePositionToSize:self.renderProcess.renderSize contentMode:MetalImageContentModeScaleToFill];
        _positionBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&position length:sizeof(position) options:0];
        _positionBuffer.label = @"Position";
    }
    return _positionBuffer;
}

- (id<MTLBuffer>)textureCoorBuffer {
    if (!_textureCoorBuffer) {
        // 默认不做旋转
        MetalImageCoordinate textureCoor = [self.texture textureCoordinatesToOrientation:self.texture.orientation];
        _textureCoorBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&textureCoor length:sizeof(textureCoor) options:0];
        _textureCoorBuffer.label = @"Texture Coordinates";
    }
    return _textureCoorBuffer;
}
@end
