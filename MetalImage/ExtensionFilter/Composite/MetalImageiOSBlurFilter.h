//
//  MetalImageiOSBlurFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageFilter.h"
#import "MetalImageLuminanceFilter.h"
#import "MetalImageSaturationFilter.h"
#import "MetalImageGaussianBlurFilter.h"

@interface MetalImageiOSBlurFilter : NSObject <MetalImageTarget, MetalImageSource, MetalImageRender>
@property (nonatomic, assign) float blurRadiusInPixels;
@property (nonatomic, assign) float texelSpacingMultiplier;
@property (nonatomic, assign) float saturation;
@property (nonatomic, assign) float luminance;

/**
 *  使用该接口实现完整毛玻璃渲染
 */
- (void)renderToResource:(MetalImageTextureResource *)resource;
@end
