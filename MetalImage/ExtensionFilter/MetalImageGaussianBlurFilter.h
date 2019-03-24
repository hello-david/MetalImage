//
//  MetalImageGaussianBlurFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageFilter.h"

@interface MetalImageGaussianBlurFilter : MetalImageFilter
@property (nonatomic, assign) float blurRadiusInPixels;
@property (nonatomic, assign) float texelSpacingMultiplier;// [1.0 ~ 2.0]

+ (NSString *)vertexShaderForBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
+ (NSString *)fragmentShaderForBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
@end
