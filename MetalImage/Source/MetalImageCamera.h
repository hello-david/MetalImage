//
//  MetalImageCamera.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "MetalImageSource.h"
#import "MetalImageAudioResource.h"
#import "MetalImageTextureResource.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageCamera : NSObject <MetalImageSource>
@property (nonatomic, strong, readonly) MetalImageSource *source;

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)present
                       cameraPosition:(AVCaptureDevicePosition)cameraPosition;

- (void)startCapture;
- (void)stopCapture;
@end

NS_ASSUME_NONNULL_END
