//
//  MetalImageHueFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/3/25.
//

#import "MetalImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageHueFilter : MetalImageFilter
@property (assign, nonatomic) float hue;// 建议[-1.0, 1.0], 默认0.0
@end

NS_ASSUME_NONNULL_END
