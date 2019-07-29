//
//  MetalImageDevice.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLDevice.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLPixelFormat.h>
#import <MetalKit/MTKTextureLoader.h>
#import "MetalImageTextureCache.h"

#define METAL_SHADER_STRING(text)   @ #text
#define kMetalImageDefaultVertex    @"oneInputVertex"
#define kMetalImageDefaultFragment  @"passthroughFragment"

NS_ASSUME_NONNULL_BEGIN

extern NSString* const MetalImageBundleName;

@interface MetalImageDevice : NSObject
@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, assign) MTLPixelFormat pixelFormat;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) MetalImageTextureCache *textureCache;
@property (nonatomic, strong) MTKTextureLoader *textureLoader;

+ (instancetype)shared;
@end

NS_ASSUME_NONNULL_END
