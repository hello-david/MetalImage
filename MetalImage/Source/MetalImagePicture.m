//
//  MetalImagePicture.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImagePicture.h"

@interface MetalImagePicture()
@property (nonatomic, strong) MetalImageTextureResource *resource;
@property (nonatomic, strong) MetalImageSource *source;
@end

@implementation MetalImagePicture

- (instancetype)initWithImage:(UIImage *)image {
    if (self = [super init]) {
        _originImage = image;
        _source = [[MetalImageSource alloc] init];
    }
    return self;
}

- (void)setOriginImage:(UIImage *)originImage {
    _originImage = originImage;
    if (_originImage != nil) {
        __weak typeof(self) weakSelf = self;
         dispatch_barrier_async([MetalImageDevice shared].commonProcessQueue, ^{
             weakSelf.resource = nil;
         });
    }
}

- (MetalImageResource *)resource {
    if (!_resource) {
        id<MTLTexture> texutre = nil;
        if (@available(iOS 9.0, *)) {
            NSError *err = nil;
            texutre = [[MetalImageDevice shared].textureLoader newTextureWithCGImage:[_originImage CGImage] options:NULL error:&err];
        } else {
            texutre = [MetalImageTexture textureFromImage:_originImage device:[MetalImageDevice shared].device];
        }
        _resource = [[MetalImageTextureResource alloc] initWithTexture:[[MetalImageTexture alloc] initWithTexture:texutre orientation:kMetalImagePortrait willCache:NO]];
    }
    return _resource;
}

- (void)processImage {
    if (!self.source.haveTarget) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async([MetalImageDevice shared].commonProcessQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        [strongSelf send:strongSelf.resource withTime:kCMTimeInvalid];
    });
}

- (void)processImageByFilters:(NSArray<MetalImageFilter *> *)filters completion:(MetalImagePictureProcessCompletion)completion {
    if (!filters || !filters.count) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async([MetalImageDevice shared].commonProcessQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (!strongSelf) {
            !completion ? : completion(nil);
            return;
        }
        
        for (MetalImageFilter *filter in filters) {
            [strongSelf.resource startRenderProcess:^(id<MTLRenderCommandEncoder> renderEncoder) {
                [filter renderToEncoder:renderEncoder withResource:strongSelf.resource];
            } completion:nil];
        }
        [strongSelf.resource endRenderProcess];
        !completion ? : completion([strongSelf.resource.texture imageFromTexture]);
        
        // 滤镜效果渲染完后扔到Picture的链路中
        [strongSelf send:strongSelf.resource withTime:kCMTimeInvalid];
    });
}

#pragma mark - Source Protocol
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    [self.source send:resource withTime:time];
}

- (void)setTarget:(id<MetalImageTarget>)target {
    [self.source setTarget:target];
}

- (void)addAsyncTarget:(id<MetalImageTarget>)target {
    [self.source addAsyncTarget:target];
}

- (void)removeTarget:(id<MetalImageTarget>)target {
    [self.source removeTarget:target];
}

- (void)removeAllTarget {
    [self.source removeAllTarget];
}
@end
