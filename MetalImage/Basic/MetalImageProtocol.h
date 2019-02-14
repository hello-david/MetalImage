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

@protocol MetalImageSource <NSObject>
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time;

- (void)setTarget:(id<MetalImageTarget>)target;
- (void)addAsyncTarget:(id<MetalImageTarget>)target;
- (void)removeTarget:(id<MetalImageTarget>)target;
- (void)removeAllTarget;
@end

@protocol MetalImageTarget <NSObject>
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time;
@end

