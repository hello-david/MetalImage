//
//  MetalImageCropFilter.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/12.
//

#import "MetalImageFilter.h"
@interface MetalImageCropFilter : MetalImageFilter
@property (assign, nonatomic) CGRect cropRegion;

- (instancetype)initWithCropRegin:(CGRect)cropRegion;
@end
