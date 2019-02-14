//
//  MetalImageResource.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MetalImageResourceType) {
    kMetalImageResourceTypeImage,
    kMetalImageResourceTypeAudio
};

@interface MetalImageResource : NSObject 
@property (nonatomic, assign) MetalImageResourceType type;
@property (nonatomic, weak) dispatch_queue_t processingQueue;

- (nullable MetalImageResource *)newResourceFromSelf;
@end
