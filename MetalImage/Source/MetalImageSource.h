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
@property (nonatomic, assign, readonly) BOOL haveTarget;

/**
 *  设置分发链路的目标
 *  第一目标为同步目标，使用同一份资源
 *  其他目标为异步目标，自动拷贝一份资源再传递下去
 *
 *  @param target 遵循输出目标协议的对象
 */
- (void)addTarget:(id<MetalImageTarget>)target;

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

/**
 *  这个分发节点的目标
 *
 *  @return 分发目标
 */
- (NSArray<id<MetalImageTarget>> *)targets;
@end

NS_ASSUME_NONNULL_END
