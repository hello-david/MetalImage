//
//  MetalImagePicture.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import <Foundation/Foundation.h>
#import "MetalImageSource.h"
#import "MetalImageTextureResource.h"
#import "MetalImageFilter.h"

typedef void(^MetalImagePictureProcessCompletion)(UIImage *processedImage);

NS_ASSUME_NONNULL_BEGIN

@interface MetalImagePicture : NSObject <MetalImageSource>
@property (nonatomic, strong) UIImage *originImage;
@property (nonatomic, strong, readonly) MetalImageSource *source;

- (instancetype)initWithImage:(UIImage *)image;
- (void)processImage;
- (void)processImageByFilters:(NSArray<MetalImageFilter *> *)filters completion:(MetalImagePictureProcessCompletion)completion;
@end

NS_ASSUME_NONNULL_END
