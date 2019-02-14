//
//  MetalImageFilter.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import <Foundation/Foundation.h>
#import "MetalImageProtocol.h"
#import "MetalImageSource.h"
#import "MetalImageTextureResource.h"

@interface MetalImageFilter : NSObject <MetalImageSource, MetalImageTarget>
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPielineState;
@property (nonatomic, strong, readonly) MetalImageSource *source;

- (instancetype)initWithVertexFunction:(NSString *)vertexFunction
                      fragmentFunction:(NSString *)fragmentFunction
                               library:(id<MTLLibrary>)library;
/**
 *  设置渲染过程中目标纹理的大小
 *
 *  @param renderSize   目标纹理大小
 */
- (void)setRenderSize:(CGSize)renderSize;

/**
 *  CommandBuffer由外部管理(不生成也不Commit），内部每次生成一个RenderEncoder并渲染交换纹理
 *
 *  @param commandBuffer    外部生成的commandBuffer
 *  @param resource         待渲染的资源
 */
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageTextureResource *)resource;

/**
 *  RenderEncoder由外部管理(不生成也不Encode)，内部实现Draw-Call渲染
 *
 *  @param renderEncoder    外部生成的commandBuffer
 *  @param resource         待渲染的资源
 */
- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource;
@end

