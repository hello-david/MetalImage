//
//  MetalImageGaussianBlurFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageFilter.h"

@interface MetalImageGaussianBlurFilter : MetalImageFilter
@property (nonatomic, assign) float blurRadiusInPixels;// 默认4.0
@property (nonatomic, assign) float texelSpacingMultiplier;// 默认2.0

+ (NSString *)vertexShaderForBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
+ (NSString *)fragmentShaderForBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma;
@end
