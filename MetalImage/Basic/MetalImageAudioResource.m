//
//  MetalImageAudioResource.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageAudioResource.h"

@interface MetalImageAudioResource()
@property (nonatomic, assign) CMSampleBufferRef audioBuffer;
@end

@implementation MetalImageAudioResource
- (void)dealloc {
    CFRelease(_audioBuffer);
}

- (instancetype)init {
    if (self = [super init]) {
        self.type = kMetalImageResourceTypeAudio;
    }
    return self;
}

- (instancetype)initWithBuffer:(CMSampleBufferRef)audioBuffer {
    if (self = [super init]) {
        self.type = kMetalImageResourceTypeAudio;
        _audioBuffer = audioBuffer;
        CFRetain(_audioBuffer);
    }
    return self;
}

- (MetalImageResource *)newResourceFromSelf {
    MetalImageAudioResource *newOne = [[MetalImageAudioResource alloc] initWithBuffer:_audioBuffer];
    return newOne;
}
@end
