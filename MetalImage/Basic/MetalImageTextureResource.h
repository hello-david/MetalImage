//
//  MetalImageTextureResource.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageResource.h"
#import "MetalImageRenderProcess.h"

NS_ASSUME_NONNULL_BEGIN
@interface MetalImageTextureResource : MetalImageResource
@property (nonatomic, readonly) MetalImageTexture *texture;
@property (nonatomic, readonly) MetalImageRenderProcess *renderProcess;

- (instancetype)init __attribute__((deprecated("此方法已弃用,请使用initWithTexture:方法")));
- (instancetype)initWithTexture:(MetalImageTexture *)texture;

/**
 *  拷贝内部当前的纹理资源
 *
 *  @return 返回一个新的资源对象
 */
- (MetalImageResource *)newResourceFromSelf;
@end

NS_ASSUME_NONNULL_END
