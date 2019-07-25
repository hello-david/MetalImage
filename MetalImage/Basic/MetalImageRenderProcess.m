//
//  MetalImageRenderProcess.m
//  MetalImage
//
//  Created by David.Dai on 2019/5/16.
//

#import "MetalImageRenderProcess.h"

@interface MetalImageRenderProcess()
@property (nonatomic, strong) MTLRenderPassDescriptor *renderPassDecriptor;
@property (nonatomic, strong) id<MTLCommandBuffer> renderCommandBuffer;
@property (nonatomic, strong) id<MTLRenderCommandEncoder> renderEncoder;

@property (nonatomic, strong) MetalImageTexture *texture;
@property (nonatomic, strong) MetalImageTexture *targetTexture;
@property (nonatomic, strong) id<MTLBuffer> positionBuffer;
@property (nonatomic, strong) id<MTLBuffer> textureCoorBuffer;
@end

@implementation MetalImageRenderProcess

- (instancetype)initWithTexture:(MetalImageTexture *)texture {
    if (self = [super init]) {
        _texture = texture;
        _targetSize = CGSizeMake(texture.width, texture.height);
    }
    return self;
}

- (void)dealloc {
    [[MetalImageDevice shared].textureCache cacheTexture:self.texture];
}

- (void)addRenderProcess:(MetalImageRenderProcessBlock)processing {
    @autoreleasepool {
        if (processing) {
            processing(self.renderEncoder);
        }
        
        _targetTexture.orientation = _texture.orientation;
        [_renderEncoder endEncoding];
        [self swapTexture:_targetTexture];
        
        _renderEncoder = nil;
        _targetTexture = nil;
    }
}

- (void)commitRender {
    [self commitRenderWaitUntilFinish:NO completion:nil];
}

- (void)commitRenderWaitUntilFinish:(BOOL)waitUntilFinish completion:(MetalImageRenderCompletionBlock)completion {
    if (!_renderCommandBuffer || _renderCommandBuffer.status > MTLCommandBufferStatusEnqueued) {
        _renderCommandBuffer = nil;
        return;
    }
    
    if (completion) {
        __weak typeof(self) weakSelf = self;
        [_renderCommandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull commandbuffer) {
            completion(weakSelf.texture);
        }];
    }
    
    [_renderCommandBuffer commit];
    !waitUntilFinish ? : [_renderCommandBuffer waitUntilCompleted];
    _renderEncoder = nil;
    _renderCommandBuffer = nil;
    _targetTexture = nil;
}

- (void)swapTexture:(MetalImageTexture *)texture {
    [[MetalImageDevice shared].textureCache cacheTexture:self.texture];
    
    self.texture = nil;
    self.texture = texture;
    _targetSize = CGSizeMake(texture.width, texture.height);
}

- (void)setTargetSize:(CGSize)targetSize {
    if (!CGSizeEqualToSize(_targetSize, targetSize)) {
        [self commitRenderWaitUntilFinish:YES completion:nil];
        _targetSize = targetSize;
    }
}

#pragma mark - Getter
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
        self.renderPassDecriptor.colorAttachments[0].texture = self.targetTexture.metalTexture;
        _renderEncoder = [self.renderCommandBuffer renderCommandEncoderWithDescriptor:self.renderPassDecriptor];
    }
    return _renderEncoder;
}

- (MetalImageTexture *)targetTexture {
    if (!_targetTexture) {
        CGSize targetSize = CGSizeEqualToSize(_targetSize, CGSizeZero) ? _texture.size : _targetSize;
        _targetTexture = [[MetalImageDevice shared].textureCache fetchTexture:targetSize
                                                                  pixelFormat:_texture.metalTexture.pixelFormat];
        _targetTexture.orientation = _texture.orientation;
    }
    return _targetTexture;
}

- (id<MTLBuffer>)positionBuffer {
    if (!_positionBuffer) {
        MetalImageCoordinate position = [self.texture texturePositionToSize:self.texture.size contentMode:MetalImageContentModeScaleToFill];
        _positionBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&position length:sizeof(position) options:0];
        _positionBuffer.label = @"Default Position";
    }
    return _positionBuffer;
}

- (id<MTLBuffer>)textureCoorBuffer {
    if (!_textureCoorBuffer) {
        MetalImageCoordinate textureCoor = [self.texture textureCoordinatesToOrientation:self.texture.orientation];
        _textureCoorBuffer = [[MetalImageDevice shared].device newBufferWithBytes:&textureCoor length:sizeof(textureCoor) options:0];
        _textureCoorBuffer.label = @"Default Texture Coordinates";
    }
    return _textureCoorBuffer;
}
@end
