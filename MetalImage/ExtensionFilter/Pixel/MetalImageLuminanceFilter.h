//
//  MetalImageLuminanceFilter.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageFilter.h"

@interface MetalImageLuminanceFilter : MetalImageFilter
@property (assign, nonatomic) float rangeReductionFactor;// 建议[-1.0, 1.0]，默认0.0
@end
