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

#define METAL_SHADER_STRING(text) @ #text

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageFilter : NSObject <MetalImageSource, MetalImageTarget, MetalImageRender>
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPielineState;
@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, strong, readonly) MetalImageSource *source;

- (instancetype)initWithVertexFunction:(NSString *)vertexFunction
                      fragmentFunction:(NSString *)fragmentFunction
                               library:(id<MTLLibrary>)library;

/**
 *  CommandBuffer由外部管理(不生成也不Commit)
 *
 *  @param commandBuffer    外部生成的commandBuffer
 *  @param resource         待渲染的资源
 *
 *  @dicussion
 *  内部包含一个或多个RenderEncoder并渲染后交换纹理保证输入输出有序，是一个完整的渲染流程
 *  可通过设置targetSize来指定目标纹理的大小
 */
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageTextureResource *)resource;

/**
 *  RenderEncoder由外部管理(不生成也不Encoder)
 *
 *  @param renderEncoder    外部生成的renderEncoder
 *  @param resource         待渲染的资源
 *
 *  @discussion
 *  内部包含一个或多个Draw-Call渲染不会进行结果纹理交换，不是一个完整的渲染流程
 *  可通过设置resource的targetSize来指定目标纹理的大小
 */
- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource;
@end

NS_ASSUME_NONNULL_END
