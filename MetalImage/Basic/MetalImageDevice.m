//
//  MetalImageDevice.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import "MetalImageDevice.h"
#import "NSBundle+MetalImageBundle.h"

@interface MetalImageDevice()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

@implementation MetalImageDevice
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    static MetalImageDevice *defaultDevice = nil;
    dispatch_once(&onceToken, ^{
        defaultDevice = [[self alloc] init];
    });
    return defaultDevice;
}

- (instancetype)init {
    if (self = [super init]) {
        _device = MTLCreateSystemDefaultDevice();
        static dispatch_once_t onceToken;
        static id<MTLCommandQueue> defaultCommandQueue = nil;
        dispatch_once(&onceToken, ^{
            defaultCommandQueue = [self.device newCommandQueue];
        });
        _commandQueue = defaultCommandQueue;
        _pixelFormat = MTLPixelFormatBGRA8Unorm;
    }
    return self;
}

- (MetalImageTextureCache *)textureCache {
    if (!_textureCache) {
        _textureCache = [[MetalImageTextureCache alloc] initWithDevice:_device];
    }
    return _textureCache;
}

- (dispatch_queue_t)concurrentQueue {
    if (!_concurrentQueue) {
        _concurrentQueue = dispatch_queue_create("com.MetalImage.globalProcess", DISPATCH_QUEUE_CONCURRENT);
    }
    return _concurrentQueue;
}

- (MTKTextureLoader *)textureLoader {
    if (!_textureLoader) {
        _textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    }
    return _textureLoader;
}

- (id<MTLLibrary>)library {
    if (!_library) {
        NSString *bundlePath = [NSBundle metalImage_bundleWithName:@"MetalLibrary"].bundlePath;
        NSString *defaultMetalFile = [bundlePath stringByAppendingPathComponent:@"default.metallib"];
        NSError *error = nil;
        _library = [_device newLibraryWithFile:defaultMetalFile error:&error];
    }
    return _library;
}
@end
