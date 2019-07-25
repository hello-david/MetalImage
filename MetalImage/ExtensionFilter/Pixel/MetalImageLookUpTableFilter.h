//
//  MetalImageLookUpTableFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/7/4.
//

#import "MetalImageFilter.h"
#import "MetalimageTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageLookUpTableFilter : MetalImageFilter
@property (nonatomic, strong) MetalImageTexture *lookUpTableTexture;
@property (nonatomic, assign) float intensity;
@end

NS_ASSUME_NONNULL_END
