//
//  MetalImageFilter.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import <Foundation/Foundation.h>
#import "MetalImageProtocol.h"
#import "MetalImageSource.h"
#import "MetalImageTarget.h"
#import "MetalImageResource.h"

#define METAL_SHADER_STRING(text) @ #text

NS_ASSUME_NONNULL_BEGIN
@class MetalImageFilter;
typedef void(^MetalImageFilterBlock)(BOOL beforeProcess, MetalImageResource *resource, MetalImageFilter *filter);

@interface MetalImageFilter : NSObject <MetalImageSource, MetalImageTarget, MetalImageRender>
@property (nonatomic, readonly) MetalImageSource *source;
@property (nonatomic, readonly) MetalImageTarget *target;
@property (nonatomic, copy, nullable) MetalImageFilterBlock chainProcessHandle;

- (instancetype)initWithVertexFunction:(NSString *)vertexFunction
                      fragmentFunction:(NSString *)fragmentFunction
                               library:(id<MTLLibrary>)library;

/**
 *  CommandBuffer层级的渲染
 *
 *  @param commandBuffer    外部生成的commandBuffer
 *  @param resource         待渲染的资源
 *
 *  @dicussion
 *  内部包含一个或多个RenderCommandEncoder并渲染后交换纹理保证输入输出有序
 *  可通过设置resource的targetSize来指定目标纹理的大小
 */
- (void)encodeToCommandBuffer:(id<MTLCommandBuffer>)commandBuffer withResource:(MetalImageResource *)resource;

/**
 *  CommandEncoder层级的渲染
 *
 *  @param renderEncoder    外部生成的renderCommandEncoder
 *  @param resource         待渲染的资源
 *
 *  @discussion
 *  内部包含一个或多个Draw-Call渲染不会进行结果纹理交换
 *  可通过设置resource的targetSize来指定目标纹理的大小
 */
- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageResource *)resource;
@end

NS_ASSUME_NONNULL_END
