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

@interface MetalImageDevice : NSObject
@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, assign) MTLPixelFormat pixelFormat;
@property (nonatomic, strong) dispatch_queue_t commonProcessQueue;
@property (nonatomic, strong) MetalImageTextureCache *textureCache;
@property (nonatomic, strong) MTKTextureLoader *textureLoader API_AVAILABLE(ios(9.0));

+ (instancetype)shared;
@end

