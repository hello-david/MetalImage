//
//  MetalImageLookUpTableFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/7/4.
//

#import "MetalImageFilter.h"
#import "MetalImageTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageLookUpTableFilter : MetalImageFilter
@property (nonatomic, strong, readonly) id<MTLTexture> lookUpTableTexture;
@property (nonatomic, assign, readonly) UInt8 sampleStep;//采样步长=分辨率/色块格数，表示每格能表示多少种颜色
@property (nonatomic, assign) float intensity;

- (instancetype)initWithLutTexture:(id<MTLTexture>)lutTexture sampleStep:(UInt8)sampleStep;
- (void)replaceLutTexture:(id<MTLTexture>)lutTexture sampleStep:(UInt8)sampleStep;
@end

NS_ASSUME_NONNULL_END
