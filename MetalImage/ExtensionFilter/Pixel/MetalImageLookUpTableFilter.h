//
//  MetalImageLookUpTableFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/7/4.
//

#import "MetalImageFilter.h"
#import "MetalImageTexture.h"

typedef NS_ENUM(NSUInteger, MetalImageLUTFilterType) {
    MetalImageLUTFilterType8_8, // 晶格数为8*8，使用右上角坐标系
    MetalImageLUTFilterType4_4  // 晶格数为4*4，使用右上角坐标系
};

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageLookUpTableFilter : MetalImageFilter
@property (nonatomic, strong, readonly) id<MTLTexture> lookUpTableTexture;
@property (nonatomic, assign, readonly) MetalImageLUTFilterType type;
@property (nonatomic, assign) float intensity;

- (instancetype)initWithLutTexture:(id<MTLTexture>)lutTexture type:(MetalImageLUTFilterType)type;
- (void)replaceLutTexture:(id<MTLTexture>)lutTexture type:(MetalImageLUTFilterType)type;
@end

NS_ASSUME_NONNULL_END
