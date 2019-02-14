//
//  MetalImageSource.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/30.
//

#import <Foundation/Foundation.h>
#import "MetalImageProtocol.h"
#import "MetalImageDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageSource : NSObject
@property (nonatomic, strong) id<MetalImageTarget> target;
@property (nonatomic, assign, readonly) BOOL haveTarget;

/**
 *  设置串行目标，使用同一份资源
 *
 *  @param target 遵循输出目标协议的对象
 */
- (void)setTarget:(id<MetalImageTarget>)target;

/**
 *  设置并行目标，当有2个以上目标时会自动拷贝一份资源再传递下去
 *
 *  @param target 遵循输出目标协议的对象
 */
- (void)addAsyncTarget:(id<MetalImageTarget>)target;

/**
 *  删除转发目标
 *
 *  @param target 遵循输出目标协议的对象
 */
- (void)removeTarget:(id<MetalImageTarget>)target;

/**
 *  删除所有转发目标
 */
- (void)removeAllTarget;

/**
 *  设置并行目标，当有2个以上目标时会自动拷贝一份资源再传递下去
 *
 *  @param resource 转发资源
 *  @param time     转发的时间
 */
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time;
@end

NS_ASSUME_NONNULL_END
