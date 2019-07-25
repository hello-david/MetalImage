//
//  MetalImageResource.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "MetalImageRenderProcess.h"

typedef NS_ENUM(NSUInteger, MetalImageResourceType) {
    MetalImageResourceTypeImage,
    MetalImageResourceTypeAudio
};

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageResource : NSObject
@property (nonatomic, readonly, nullable) CMSampleBufferRef audioBuffer;
@property (nonatomic, readonly, nullable) MetalImageTexture *texture;
@property (nonatomic, readonly, nullable) MetalImageRenderProcess *renderProcess;

@property (nonatomic, assign) MetalImageResourceType type;
@property (nonatomic, weak) dispatch_queue_t processingQueue;

+ (instancetype)audioResource:(CMSampleBufferRef)audioBuffer;
+ (instancetype)imageResource:(MetalImageTexture *)texture;

- (nullable MetalImageResource *)newResourceFromSelf;
@end

NS_ASSUME_NONNULL_END
