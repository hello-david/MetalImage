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
@property (nonatomic, assign) float blurRadiusInPixels;// 高斯模糊半径，默认8.0，当为0.0时无模糊效果
@property (nonatomic, assign) float texelSpacingMultiplier;// 采样步长，默认1.0，当为0.0时无模糊效果
@property (nonatomic, assign) float saturation;// 饱和度，默认0.0不调整，建议[-1.0, 1.0]
@property (nonatomic, assign) float luminance;// 亮度，默认0.0不调整，建议[-1.0, 1.0]

- (void)renderToResource:(MetalImageResource *)resource;
@end
