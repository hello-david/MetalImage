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
/**
 *  触发图像分发链路
 */
- (void)processImage;

/**
 *  使用一组滤镜处理图像
 *
 *  @param filters      一组滤镜
 *  @param completion   滤镜处理结果
 */
- (void)processImageByFilters:(NSArray<id<MetalImageRender>> *)filters completion:(MetalImagePictureProcessCompletion)completion;
@end

NS_ASSUME_NONNULL_END
