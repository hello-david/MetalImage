//
//  MetalImageSharpenFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageFilter.h"

@interface MetalImageSharpenFilter : MetalImageFilter
@property (assign, nonatomic) float sharpness;// [-4.0, 4.0]
@end
