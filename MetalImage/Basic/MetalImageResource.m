//
//  MetalImageResource.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/30.
//

#import "MetalImageResource.h"
@interface MetalImageResource()
@property (nonatomic, assign) CMSampleBufferRef audioBuffer;
@property (nonatomic, strong) MetalImageRenderProcess *renderProcess;
@end

@implementation MetalImageResource

+ (instancetype)audioResource:(CMSampleBufferRef)audioBuffer {
    return [[self alloc] initWithAudioBuffer:audioBuffer];
}

+ (instancetype)imageResource:(MetalImageTexture *)texture {
    return [[self alloc] initWithTexture:texture];
}

- (void)dealloc {
    if (_audioBuffer) {
        CFRelease(_audioBuffer);
    }
}

- (instancetype)initWithAudioBuffer:(CMSampleBufferRef)audioBuffer {
    if (self = [super init]) {
        _type = MetalImageResourceTypeAudio;
        _audioBuffer = audioBuffer;
        CFRetain(_audioBuffer);
    }
    return self;
}

- (instancetype)initWithTexture:(MetalImageTexture *)texture {
    if (self = [super init]) {
        _type = MetalImageResourceTypeImage;
        _renderProcess = [[MetalImageRenderProcess alloc] initWithTexture:texture];
    }
    return self;
}

- (MetalImageTexture *)texture {
    return self.renderProcess.texture;
}

- (MetalImageResource *)newResourceFromSelf {
      __block MetalImageResource *newResource = nil;
    if (MetalImageResourceTypeAudio == _type) {
        newResource = [[MetalImageResource alloc] initWithAudioBuffer:_audioBuffer];
    }
    else if (MetalImageResourceTypeImage == _type) {
        // 拷贝之前先提交之前的渲染
        [self.renderProcess commitRender];
        
        // 拷贝当前的纹理
        @autoreleasepool {
            MetalImageTexture *copyTexture = [[MetalImageDevice shared].textureCache fetchTexture:self.texture.size
                                                                                      pixelFormat:self.texture.metalTexture.pixelFormat];
            copyTexture.orientation = self.texture.orientation;
            newResource = [[MetalImageResource alloc] initWithTexture:copyTexture];
            [copyTexture replaceTexture:self.texture.metalTexture];
        }
    }
    
    return newResource;
}
@end
