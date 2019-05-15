//
//  MetalImageProtocol.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "MetalImageResource.h"
#import "MetalImageTextureResource.h"
#import "MetalImageAudioResource.h"

@protocol MetalImageTarget;
@protocol MetalImageSource;
@protocol MetalImageRender;

@protocol MetalImageSource <NSObject>
/**
 *  转发资源
 */
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time;

/**
 *  资源接收对象管理
 */
- (void)addTarget:(id<MetalImageTarget>)target;
- (void)removeTarget:(id<MetalImageTarget>)target;
- (void)removeAllTarget;
@end

@protocol MetalImageTarget <NSObject>
/**
 *  接收资源
 */
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time;
@end

@protocol MetalImageRender <NSObject>
/**
 *  独立完整的渲染流程
 */
- (void)renderToResource:(MetalImageTextureResource *)resource;
@end

