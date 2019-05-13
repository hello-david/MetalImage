//
//  MetalImageCamera.m
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import "MetalImageCamera.h"

@interface MetalImageCamera() <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureDevice *inputCamera;
@property (nonatomic, strong) AVCaptureDevice *inputMic;
@property (nonatomic, assign) AVCaptureSessionPreset inputPresent;
@property (nonatomic, assign) AVCaptureDevicePosition inputPosition;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoDataOutput *imageOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *imageInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, assign) CVMetalTextureCacheRef textureCache;

@property (nonatomic, strong) AVCaptureConnection *imageConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

@property (nonatomic, strong) dispatch_queue_t audioCaptureQueue;
@property (nonatomic, strong) dispatch_queue_t imageCaptureQueue;
@property (nonatomic, strong) dispatch_queue_t renderQueue;
@property (nonatomic, strong) dispatch_queue_t audioProcessQueue;

@property (nonatomic, strong) MetalImageSource *source;
@end

@implementation MetalImageCamera

- (instancetype)initWithSessionPreset:(AVCaptureSessionPreset)present
                       cameraPosition:(AVCaptureDevicePosition)cameraPosition {
    if (self = [super init]) {
        self.inputPresent = present;
        self.inputPosition = cameraPosition;
        self.imageCaptureQueue = dispatch_queue_create("com.MetalImage.Camera.ImageCapture", DISPATCH_QUEUE_SERIAL);
        self.audioCaptureQueue = dispatch_queue_create("com.MetalImage.Camera.AudioCapture", DISPATCH_QUEUE_SERIAL);
        self.renderQueue = dispatch_queue_create("com.MetalImage.Camera.ImageRender", DISPATCH_QUEUE_SERIAL);
        self.audioProcessQueue = dispatch_queue_create("com.MetalImage.Camera.AudioProcess", DISPATCH_QUEUE_SERIAL);
        self.source = [[MetalImageSource alloc] init];
        
        // 图像
        self.session = [[AVCaptureSession alloc] init];
        self.inputCamera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        self.imageInput = [AVCaptureDeviceInput deviceInputWithDevice:self.inputCamera error:nil];
        self.imageOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        self.imageOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
        [self.imageOutput setSampleBufferDelegate:self queue:self.imageCaptureQueue];
    
        // 音频
        self.inputMic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.inputMic error:nil];
        self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [self.audioOutput setSampleBufferDelegate:self queue:self.audioCaptureQueue];
        
        [self.session beginConfiguration];
        self.session.sessionPreset = present;
        if ([self.session canAddInput:self.imageInput]) {
            [self.session addInput:self.imageInput];
        }
        if ([self.session canAddOutput:self.imageOutput]) {
            [self.session addOutput:self.imageOutput];
        }
        if ([self.session canAddInput:self.audioInput]) {
            [self.session addInput:self.audioInput];
        }
        if ([self.session canAddOutput:self.audioOutput]) {
            [self.session addOutput:self.audioOutput];
        }
        [self.session commitConfiguration];
        
        self.imageConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
        self.audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
        
        CVReturn status = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, [MetalImageDevice shared].device, nil, &(_textureCache));
        if (status != kCVReturnSuccess) {
            assert(!"Failed to create Metal texture cache");
        }
    }
    return self;
}

- (void)dealloc {
    [self stopCapture];
}

- (void)startCapture {
    if (!self.session.isRunning) {
        [self.session startRunning];
    }
}

- (void)stopCapture {
    if (self.session.isRunning) {
        [self.session stopRunning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(nonnull CMSampleBufferRef)sampleBuffer fromConnection:(nonnull AVCaptureConnection *)connection {
    // 图像
    if (connection == self.imageConnection) {
        CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        size_t frameWidth = CVPixelBufferGetWidth(cameraFrame);
        size_t frameHeight = CVPixelBufferGetHeight(cameraFrame);
        CMTime sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if (!cameraFrame) {
            return;
        }
        CFRetain(sampleBuffer);
        
        __weak typeof(self) weakSelf = self;
        CVPixelBufferLockBaseAddress(cameraFrame, 0);
        dispatch_barrier_sync(self.renderQueue, ^{
            CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
            
            // Create CVMetal Texture
            CVReturn cvret;
            CVMetalTextureRef metalTexutre = NULL;
            cvret = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                              weakSelf.textureCache,
                                                              cameraFrame, nil,
                                                              MTLPixelFormatBGRA8Unorm,
                                                              frameWidth, frameHeight,
                                                              0,
                                                              &metalTexutre);
            if(cvret != kCVReturnSuccess) {
                assert(!"Failed to create Metal texture");
                return;
            }
            
            // Get Metal Texture
            id<MTLTexture> texture = CVMetalTextureGetTexture(metalTexutre);
            if(!texture) {
                assert(!"Failed to get metal texture from CVMetalTextureRef");
                return;
            };
            
            CFRelease(metalTexutre);
            CFRelease(sampleBuffer);
            
            MetalImageTexture *imageTexture = [[MetalImageTexture alloc] initWithTexture:texture
                                                                             orientation:kMetalImageLandscapeLeft
                                                                               willCache:NO];
            MetalImageTextureResource *imageResource = [[MetalImageTextureResource alloc] initWithTexture:imageTexture];
            imageResource.processingQueue = weakSelf.renderQueue;
            [weakSelf send:imageResource withTime:sampleTime];
        });
    }
    // 音频
    else if (connection == self.audioConnection) {
        CFRetain(sampleBuffer);
        
        __weak typeof(self) weakSelf = self;
        dispatch_barrier_sync(self.audioProcessQueue, ^{
            CMTime sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            MetalImageAudioResource *audioResource = [[MetalImageAudioResource alloc] initWithBuffer:sampleBuffer];
            [weakSelf send:audioResource withTime:sampleTime];
            
            CFRelease(sampleBuffer);
        });
    }
}

#pragma mark - Source Protocol
- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    [self.source send:resource withTime:time];
}

- (void)setTarget:(id<MetalImageTarget>)target {
    [self.source setTarget:target];
}

- (void)addAsyncTarget:(id<MetalImageTarget>)target {
    [self.source addAsyncTarget:target];
}

- (void)removeTarget:(id<MetalImageTarget>)target {
    [self.source removeTarget:target];
}

- (void)removeAllTarget {
    [self.source removeAllTarget];
}
@end
