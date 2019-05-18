//
//  MetalImageTextureCache.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import "MetalImageTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageTextureCache : NSObject
- (instancetype)initWithDevice:(id<MTLDevice>)device;

/**
 *  从缓存池中获取一张纹理(线程安全)
 *
 *  @param  size        纹理大小
 *  @param  pixelFormat 纹理像素格式
 */
- (MetalImageTexture *)fetchTexture:(CGSize)size pixelFormat:(MTLPixelFormat)pixelFormat;

/**
 *  缓存一张纹理(线程安全)
 *
 *  @param  texutre     纹理对象
 */
- (void)cacheTexture:(MetalImageTexture *)texutre;

/**
 *  清楚缓存池中所有的纹理对象(线程安全)
 */
- (void)freeAllTexture;
@end

NS_ASSUME_NONNULL_END
