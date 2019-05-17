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
         dispatch_barrier_async([MetalImageDevice shared].concurrentQueue, ^{
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
        _resource = [[MetalImageTextureResource alloc] initWithTexture:[[MetalImageTexture alloc] initWithTexture:texutre orientation:MetalImagePortrait willCache:NO]];
    }
    return _resource;
}

- (void)processImage {
    if (!self.source.haveTarget || !_originImage) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async([MetalImageDevice shared].concurrentQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        [strongSelf send:strongSelf.resource withTime:kCMTimeInvalid];
        strongSelf.resource = nil;
    });
}

- (void)processImageByFilters:(NSArray<id<MetalImageRender>> *)filters completion:(MetalImagePictureProcessCompletion)completion {
    if (!filters || !filters.count || !_originImage) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async([MetalImageDevice shared].concurrentQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            !completion ? : completion(nil);
            return;
        }
        
        for (id<MetalImageRender> filter in filters) {
            if ([filter isKindOfClass:[MetalImageFilter class]]) {
                [strongSelf.resource.renderProcess addRenderProcess:^(id<MTLRenderCommandEncoder> renderEncoder) {
                    [(MetalImageFilter*)filter renderToEncoder:renderEncoder withResource:strongSelf.resource];
                }];
            } else {
                [strongSelf.resource.renderProcess commitRenderWaitUntilFinish:YES];
                [filter renderToResource:strongSelf.resource];
            }
        }
        [strongSelf.resource.renderProcess commitRenderWaitUntilFinish:YES];
        
        UIImage *processedImage = [strongSelf.resource.texture imageFromTexture];
        strongSelf.resource = nil;
        !completion ? : completion(processedImage);
    });
}

#pragma mark - Source Protocol
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    [self.source send:resource withTime:time];
}

- (void)addTarget:(id<MetalImageTarget>)target {
    [self.source addTarget:target];
}

- (void)removeTarget:(id<MetalImageTarget>)target {
    [self.source removeTarget:target];
}

- (void)removeAllTarget {
    [self.source removeAllTarget];
}
@end
