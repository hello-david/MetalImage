//
//  MetalImageContrastFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/3/24.
//

#import "MetalImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageContrastFilter : MetalImageFilter
@property (assign, nonatomic) float contrast;// 建议[0.0, 2.0], 默认1.0
@end

NS_ASSUME_NONNULL_END
