//
//  MetalImageAudioResource.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageResource.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageAudioResource : MetalImageResource
@property (nonatomic, assign, readonly) CMSampleBufferRef audioBuffer;

- (instancetype)init __attribute__((deprecated("此方法已弃用,请使用initWithBuffer:方法")));
- (instancetype)initWithBuffer:(CMSampleBufferRef)audioBuffer;

/**
 *  audioBuffer计数+1并生成一个新Resource返回
 *
 *  @return 返回一个新的资源对象
 */
- (MetalImageResource *)newResourceFromSelf;
@end

NS_ASSUME_NONNULL_END
