//
//  MetalImageTextureResource.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageTextureResource.h"

@interface MetalImageTextureResource ()
@property (nonatomic, strong) MetalImageTexture *texture;
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDecriptor;

@property (nonatomic, strong) MetalImageTexture *renderingTexture;
@property (nonatomic, strong) id<MTLCommandBuffer> renderCommandBuffer;
@property (nonatomic, strong) id<MTLRenderCommandEncoder> renderEncoder;
@property (nonatomic, assign) CGSize renderSize;
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
        _texture = texture;
        _renderSize = CGSizeMake(texture.width, texture.height);
    }
    return self;
}

- (MetalImageResource *)newResourceFromSelf {
    // 拷贝之前先提交之前的渲染
    if (_renderCommandBuffer && _renderCommandBuffer.status <= MTLCommandBufferStatusEnqueued) {
        [_renderCommandBuffer commit];
        [_renderCommandBuffer waitUntilCompleted];
        _renderEncoder = nil;
        _renderCommandBuffer = nil;
        _renderingTexture = nil;
    }
    
    // 拷贝当前的纹理
    __block MetalImageTextureResource *newResource = nil;
    @autoreleasepool {
        MetalImageTexture *copyTexture = [[MetalImageDevice shared].textureCache fetchTexture:_texture.size
                                                                                  pixelFormat:_texture.metalTexture.pixelFormat];
        copyTexture.orientation = _texture.orientation;
        newResource = [[MetalImageTextureResource alloc] initWithTexture:copyTexture];
        [copyTexture replaceTexture:_texture.metalTexture];
    }
    
    return newResource;
}

- (void)swapTexture:(MetalImageTexture *)texture {
    [[MetalImageDevice shared].textureCache cacheTexture:self.texture];
    
    self.texture = nil;
    self.texture = texture;
    _renderSize = CGSizeMake(texture.width, texture.height);
}

- (void)setRenderSize:(CGSize)size {
    if (CGSizeEqualToSize(size, _renderSize)) {
        return;
    }
    _renderSize = size;
    [self endRenderProcess];
}

- (void)startRenderProcess:(MetalImageResourceRenderProcess)processing completion:(MetalImageResourceRenderCompletion)completion {
    @autoreleasepool {
        if (processing) {
            processing(self.renderEncoder);
        }
        _renderingTexture.orientation = _texture.orientation;
        
        [_renderEncoder endEncoding];
        [self swapTexture:_renderingTexture];
        
        _renderEncoder = nil;
        _renderingTexture = nil;
        
        if (completion) {
            completion();
        }
    }
}

- (void)endRenderProcess {
    [self endRenderProcessUntilCompleted:NO];
}

- (void)endRenderProcessUntilCompleted:(BOOL)waitUntilCompleted {
    if (!_renderCommandBuffer || _renderCommandBuffer.status > MTLCommandBufferStatusEnqueued) {
        _renderCommandBuffer = nil;
        return;
    }
    [_renderCommandBuffer commit];
    waitUntilCompleted ? [_renderCommandBuffer waitUntilCompleted] : 0;
    
    _renderEncoder = nil;
    _renderCommandBuffer = nil;
    _renderingTexture = nil;
}

#pragma mark - Custom Acessors
- (id<MTLBuffer>)positionBuffer {
    if (!_positionBuffer) {
        // 默认不做比例调整
        MetalImageCoordinate position = [self.texture texturePositionToSize:self.renderSize contentMode:MetalImageContentModeScaleToFill];
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

- (MTLRenderPassDescriptor *)renderPassDecriptor {
    if (!_renderPassDecriptor) {
        _renderPassDecriptor = [[MTLRenderPassDescriptor alloc] init];
        _renderPassDecriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderPassDecriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _renderPassDecriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1);
    }
    return _renderPassDecriptor;
}

- (id<MTLCommandBuffer>)renderCommandBuffer {
    if (!_renderCommandBuffer) {
        _renderCommandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
    }
    return _renderCommandBuffer;
}

- (id<MTLRenderCommandEncoder>)renderEncoder {
    if (!_renderEncoder) {
        self.renderPassDecriptor.colorAttachments[0].texture = self.renderingTexture.metalTexture;
        _renderEncoder = [self.renderCommandBuffer renderCommandEncoderWithDescriptor:self.renderPassDecriptor];
    }
    return _renderEncoder;
}

- (MetalImageTexture *)renderingTexture {
    if (!_renderingTexture) {
        CGSize textureSize = CGSizeEqualToSize(_renderSize, CGSizeZero) ? CGSizeMake(_texture.width, _texture.height) : _renderSize;
        _renderingTexture = [[MetalImageDevice shared].textureCache fetchTexture:textureSize
                                                                       pixelFormat:_texture.metalTexture.pixelFormat];
        _renderingTexture.orientation = _texture.orientation;
    }
    return _renderingTexture;
}
@end
