//
//  MetalImageTextureResource.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageResource.h"
#import "MetalImageDevice.h"
#import "MetalImageTexture.h"

NS_ASSUME_NONNULL_BEGIN
typedef void(^MetalImageResourceRenderProcess)(id<MTLRenderCommandEncoder> renderEncoder);
typedef void(^__nullable MetalImageResourceRenderCompletion)(void);

@interface MetalImageTextureResource : MetalImageResource
@property (nonatomic, readonly) MetalImageTexture *texture;
@property (nonatomic, readonly) MTLRenderPassDescriptor *renderPassDecriptor;
@property (nonatomic, readonly) CGSize renderSize;
@property (nonatomic, strong) id<MTLBuffer> positionBuffer;
@property (nonatomic, strong) id<MTLBuffer> textureCoorBuffer;

- (instancetype)init __attribute__((deprecated("此方法已弃用,请使用initWithTexture:方法")));
- (instancetype)initWithTexture:(MetalImageTexture *)texture;

/**
 *  拷贝内部当前的纹理资源
 *
 *  @return 返回一个新的资源对象
 */
- (MetalImageResource *)newResourceFromSelf;

/**
 *  设置渲染过程中目标纹理的大小
 *
 *  @param size 目标纹理大小
 */
- (void)setRenderSize:(CGSize)size;

/**
 *  替换这个资源对象的纹理，用于原始纹理和目标纹理交换
 *
 *  @param texture 目标纹理
 */
- (void)swapTexture:(MetalImageTexture *)texture;

/**
 *  在同一个CommandBuffer中进行渲染操作，会自动交换目标纹理，不要在外部调用[renderEncoder endEncoding]
 *
 *  @param processing   给外部一个RenderEncoder并利用它实现Draw-Call的同步闭包
 *  @param completion   外部实现Draw-Call后的同步闭包
 */
- (void)startRenderProcess:(MetalImageResourceRenderProcess)processing completion:(MetalImageResourceRenderCompletion)completion;

/**
 *  将会Commit内部的Commandbuffer，在独立使用一个新的commandBuffer假如有enqueue需要先把resource内置CommandBuffer的提交了
 */
- (void)endRenderProcess;
- (void)endRenderProcessUntilCompleted:(BOOL)waitUntilCompleted ;
@end

NS_ASSUME_NONNULL_END
