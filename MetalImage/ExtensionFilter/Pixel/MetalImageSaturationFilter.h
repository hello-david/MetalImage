//
//  MetalImageSaturationFilter.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageFilter.h"

@interface MetalImageSaturationFilter : MetalImageFilter
@property (assign, nonatomic) float saturation; // 建议[0.0, 2.0], 默认1.0
@end
