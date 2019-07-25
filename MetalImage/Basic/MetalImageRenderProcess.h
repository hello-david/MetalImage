//
//  MetalImageRenderProcess.h
//  MetalImage
//
//  Created by David.Dai on 2019/5/16.
//

#import <Foundation/Foundation.h>
#import "MetalImageDevice.h"
#import "MetalImageTexture.h"

NS_ASSUME_NONNULL_BEGIN
@class MetalImageRenderProcess;

typedef void(^MetalImageRenderProcessBlock)(id<MTLRenderCommandEncoder> renderEncoder);
typedef void(^MetalImageRenderCompletionBlock)(MetalImageTexture *renderedTexture);

@interface MetalImageRenderProcess : NSObject
@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, readonly) MetalImageTexture *texture;       // 当前纹理
@property (nonatomic, readonly) MetalImageTexture *targetTexture; // 渲染结果纹理
@property (nonatomic, readonly) id<MTLBuffer> positionBuffer;     // 整个渲染空间
@property (nonatomic, readonly) id<MTLBuffer> textureCoorBuffer;  // 整张图片

- (instancetype)initWithTexture:(MetalImageTexture *)texture;

/**
 *  在同一个CommandBuffer中进行渲染
 *
 *  @param processing   给外部一个RenderEncoder并利用它实现Draw-Call
 *
 *  @discussion
 *  会自动交换目标纹理，不要在外部调用[renderEncoder endEncoding]
 */
- (void)addRenderProcess:(MetalImageRenderProcessBlock)processing;

/**
 *  将会Commit内部的Commandbuffer
 *
 *  @discussion
 *  在使用外部的CommandBuffer时有enqueue需要先把内置CommandBuffer的提交了
 */
- (void)commitRender;
- (void)commitRenderWaitUntilFinish:(BOOL)waitUntilFinish completion:(MetalImageRenderCompletionBlock _Nullable)completion;

/**
 *  替换这个资源对象的纹理，用于原始纹理和目标纹理交换
 *
 *  @param texture 目标纹理
 */
- (void)swapTexture:(MetalImageTexture *)texture;
@end

NS_ASSUME_NONNULL_END
