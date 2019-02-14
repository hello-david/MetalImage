//
//  MetalImageMovieWriter.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/13.
//

#import "MetalImageMovieWriter.h"

@interface MetalImageMovieWriter()
@property (nonatomic, strong) dispatch_queue_t writerQueue;
@property (nonatomic, strong) NSURL *storageUrl;
@property (nonatomic, assign) CGSize renderSize;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelbufferAdaptor;
@property (nonatomic, strong) AVAssetWriterInput *imageWirterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic, assign) AVFileType fileType;

@property (nonatomic, assign) BOOL imageWriteFinish;
@property (nonatomic, assign) BOOL audioWriteFinish;
@property (nonatomic, assign) BOOL appendImageFirst;
@property (nonatomic, assign) BOOL haveAppedImage;

@property (nonatomic, assign) CMTime lastImageTime;
@property (nonatomic, assign) CMTime lastAudioTime;

@property (nonatomic, strong) MetalImageTarget *renderTarget;
@end

@implementation MetalImageMovieWriter

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (instancetype)initWithStorageUrl:(NSURL *)storageUrl size:(CGSize)size {
    if (self = [super init]) {
        _storageUrl = storageUrl;
        _renderSize = size;
        [self commitInit];
    }
    return self;
}

- (void)commitInit {
    _writerQueue = dispatch_queue_create("com.MetalImage.MovieWriter", DISPATCH_QUEUE_SERIAL);
    _backgroundType = kMetalImagContentBackgroundColor;
    _fileType = AVFileTypeQuickTimeMovie;
    
    _lastImageTime = kCMTimeZero;
    _lastAudioTime = kCMTimeZero;
    _appendImageFirst = YES;
    _haveAppedImage = NO;
    
    _renderTarget = [[MetalImageTarget alloc] initWithDefaultLibraryWithVertex:@"oneInputVertex"
                                                                        fragment:@"passthroughFragment"];
    _renderTarget.fillMode = kMetalImageContentModeScaleAspectFit;

    [self initAssetWriter];
    [self initImageWirterInput];
}

- (MetalImageContentMode)fillMode {
    return _renderTarget.fillMode;
}

- (void)setFillMode:(MetalImageContentMode)fillMode {
    _renderTarget.fillMode = fillMode;
}

- (void)setHaveAudioTrack:(BOOL)haveAudioTrack {
    if (haveAudioTrack && _assetWriter.status == AVAssetWriterStatusUnknown) {
        [self initAudioWriterInput];
    }
}

- (UIColor *)backgroudColor {
    if (!_backgroudColor) {
        _backgroudColor = [UIColor blackColor];
    }
    return _backgroudColor;
}

- (void)initAssetWriter {
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_storageUrl fileType:_fileType error:&error];
    if (error != nil) {
        assert(false);
        NSLog(@"%@ Asset Writer 创建失败 :%@", [self class], error);
    }
    _assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);// 最小采样时间间隔, 需要格式支持
}

- (void)initImageWirterInput {
    CGSize outputSize = _renderSize;
    NSDictionary *frameEncoderSettings =@{ AVVideoCodecKey  :   AVVideoCodecH264,
                                           AVVideoWidthKey  :   @(outputSize.width),
                                           AVVideoHeightKey :   @(outputSize.height)};
    _imageWirterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:frameEncoderSettings];
    _imageWirterInput.expectsMediaDataInRealTime = false;
    
    NSDictionary *pixelBufferAttributes = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA),
                                            (__bridge NSString *)kCVPixelBufferWidthKey           : @(outputSize.width),
                                            (__bridge NSString *)kCVPixelBufferHeightKey          : @(outputSize.height)};
    
    _pixelbufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_imageWirterInput
                                                                                           sourcePixelBufferAttributes:pixelBufferAttributes];
    
    if([_assetWriter canAddInput:_imageWirterInput]) {
        [_assetWriter addInput:_imageWirterInput];
    }
}

- (void)initAudioWriterInput {
    NSDictionary *audioOutputSettings = nil;
    AVAudioSession *sharedAudioSession = [AVAudioSession sharedInstance];
    double sampleRate;
    if ([sharedAudioSession respondsToSelector:@selector(sampleRate)]) {
        [sharedAudioSession setPreferredSampleRate:44100.0 error:nil];
        sampleRate = [sharedAudioSession preferredSampleRate];
    }
    else {
        sampleRate = [[AVAudioSession sharedInstance] sampleRate];
    }
    
    // 音轨0, 单通道, 64000码率, 44100采样率, AAC压缩编码格式
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSData *aclData = [NSData dataWithBytes:&acl length:sizeof(acl)];
    
    audioOutputSettings = @{AVFormatIDKey           : @(kAudioFormatMPEG4AAC),
                            AVNumberOfChannelsKey   : @(1),
                            AVSampleRateKey         : @(sampleRate),
                            AVChannelLayoutKey      : aclData,
                            AVEncoderBitRateKey     : @(64000)};

    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    _audioWriterInput.expectsMediaDataInRealTime = YES;
    
    if([_assetWriter canApplyOutputSettings:audioOutputSettings forMediaType:AVMediaTypeAudio]) {
        [_assetWriter addInput:_audioWriterInput];
    }
}

#pragma mark - Writer Control
- (void)startRecording {
    NSError *error = self.assetWriter.error;
    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        error = kMTMIMovieWriterCancelError;
    }
    
    if (_assetWriter.status != AVAssetWriterStatusUnknown) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.startHandle) {
                self.startHandle(error);
            }
            self.startHandle = nil;
        });
        return;
    }
    
    _haveAppedImage = NO;
     __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_writerQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        [strongSelf.assetWriter startWriting];
        if (strongSelf.startHandle) {
            strongSelf.startHandle(strongSelf.assetWriter.error);
        }
        strongSelf.startHandle = nil;
    });
}

- (void)cancelRecording {
    NSError *error = self.assetWriter.error;
    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        error = kMTMIMovieWriterCancelError;
    }
    
    if (_assetWriter.status != AVAssetWriterStatusWriting) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completeHandle) {
                self.completeHandle(error);
            }
            self.completeHandle = nil;
        });
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_writerQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (strongSelf.assetWriter.status == AVAssetWriterStatusWriting) {
            if (!strongSelf.imageWriteFinish) {
                strongSelf.imageWriteFinish = YES;
                [strongSelf.imageWirterInput markAsFinished];
            }
            if (!strongSelf.audioWriteFinish) {
                strongSelf.audioWriteFinish = YES;
                [strongSelf.audioWriterInput markAsFinished];
            }
        }

        [strongSelf.assetWriter cancelWriting];
    });
}

- (void)finishRecording {
    NSError *error = self.assetWriter.error;
    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        error = kMTMIMovieWriterCancelError;
    }
    
    if (self.assetWriter.status != AVAssetWriterStatusWriting) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completeHandle) {
                self.completeHandle(error);
            }
            self.completeHandle = nil;
        });
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(_writerQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (strongSelf.assetWriter.status == AVAssetWriterStatusWriting) {
            if (!strongSelf.imageWriteFinish) {
                strongSelf.imageWriteFinish = YES;
                [strongSelf.imageWirterInput markAsFinished];
            }
            if (!strongSelf.audioWriteFinish) {
                strongSelf.audioWriteFinish = YES;
                [strongSelf.audioWriterInput markAsFinished];
            }
        }
        
        // 以图像为结尾时间
        [strongSelf.assetWriter endSessionAtSourceTime:strongSelf.lastImageTime];
        [strongSelf.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (strongSelf.completeHandle) {
                    strongSelf.completeHandle(nil);
                }
                strongSelf.completeHandle = nil;
            });
        }];
    });
}

#pragma mark - Target Protocol
- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (!resource) {
        return;
    }
    
    // 不是在写入状态
    if (_assetWriter.status != AVAssetWriterStatusWriting) {
        if (resource.type == kMetalImageResourceTypeImage) {
            [[MetalImageDevice shared].textureCache cacheTexture:((MetalImageTextureResource *)resource).texture];
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(_writerQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        switch (resource.type) {
            case kMetalImageResourceTypeImage:
                [strongSelf imageProcess:(MetalImageTextureResource *)resource time:time];
                [[MetalImageDevice shared].textureCache cacheTexture:((MetalImageTextureResource *)resource).texture];
                break;
                
            case kMetalImageResourceTypeAudio:
                [strongSelf audioProcess:(MetalImageAudioResource *)resource time:time];
                break;
            default:
                break;
        }
    });
}

#pragma mark - Pixel Write Process
- (void)imageProcess:(MetalImageTextureResource *)resource time:(CMTime)time {
    // 向前的时间戳一律不接受
    if (CMTimeCompare(_lastImageTime, time) != -1) {
        return;
    }
    
    // 以图像为起始时间
    if (CMTimeCompare(_lastImageTime, kCMTimeZero) == 0) {
        [_assetWriter startSessionAtSourceTime:time];
    }
    _lastImageTime = time;
    
    // 将接收到图像渲染到目标纹理上并交换
    [self imageRenderProcess:resource];
    
    // 从目标纹理提取CVPixelBufferRef
    [MetalImageTexture textureCVPixelBufferProcess:resource.texture.metalTexture
                                             process:^(CVPixelBufferRef pixelBuffer) {
        CVPixelBufferRef pixel = pixelBuffer;
        if (!pixel) {
            return;
        }
        
        CVPixelBufferLockBaseAddress(pixel, 0);
        
        // 等待上一次写入结束
        while(!self.imageWirterInput.readyForMoreMediaData && !self.imageWriteFinish) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        
        NSError *error = nil;
        switch (self.assetWriter.status) {
            case AVAssetWriterStatusWriting: {
                // 忽略写入时Cancel的情况
                BOOL suceccsed = [self.pixelbufferAdaptor appendPixelBuffer:pixel withPresentationTime:time];
                if (!suceccsed && self.assetWriter.status == AVAssetWriterStatusFailed) {
                    error = self.assetWriter.error;
                } else {
                    self.haveAppedImage = YES;
                }
                break;
            }
                
            case AVAssetWriterStatusUnknown:
            case AVAssetWriterStatusCompleted:
            case AVAssetWriterStatusFailed: {
                error = self.assetWriter.error;
                break;
            }
            case AVAssetWriterStatusCancelled: {
                error = kMTMIMovieWriterCancelError;
                break;
            }
            default:
                break;
        }
        
        CVPixelBufferUnlockBaseAddress(pixel, 0);
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.completeHandle) {
                    self.completeHandle(error);
                }
                self.completeHandle = nil;
            });
        }
    }];
}

- (void)imageRenderProcess:(MetalImageTextureResource *)resource {
    // 生成CommandBuffer和目标纹理
    id <MTLCommandBuffer> commandBuffer = [[MetalImageDevice shared].commandQueue commandBuffer];
    MetalImageTexture *processTexture = [[MetalImageDevice shared].textureCache fetchTexture:_renderSize
                                                                                     pixelFormat:resource.texture.metalTexture.pixelFormat];
    processTexture.orientation = resource.texture.orientation;
    resource.renderPassDecriptor.colorAttachments[0].texture = processTexture.metalTexture;
    
    // 调整目标纹理背景
    if (self.backgroundType == kMetalImagContentBackgroundColor) {
        CGFloat components[4];
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        unsigned char resultingPixel[4];
        CGContextRef context = CGBitmapContextCreate(&resultingPixel, 1, 1, 8, 4, rgbColorSpace, kCGImageAlphaNoneSkipLast);
        CGContextSetFillColorWithColor(context, [self.backgroudColor CGColor]);
        CGContextFillRect(context, CGRectMake(0, 0, 1, 1));
        CGContextRelease(context);
        CGColorSpaceRelease(rgbColorSpace);
        for (int component = 0; component < 3; component++) {
            components[component] = resultingPixel[component] / 255.0f;
        }
        
        // 不支持alpha调整，还有问题未解决
        resource.renderPassDecriptor.colorAttachments[0].clearColor = MTLClearColorMake(components[0], components[1], components[2], 1.0);
    }
    else if (self.backgroundType == kMetalImagContentBackgroundFilter) {
        
    }
    
    // 调整纹理比例和方向的Buffer
    [self.renderTarget updateBufferIfNeed:resource.texture targetSize:_renderSize];
    
    // 渲染
    [commandBuffer enqueue];
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:resource.renderPassDecriptor];
    [self renderToEncoder:renderEncoder withResource:resource];
    [renderEncoder endEncoding];
    [resource swapTexture:processTexture];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
}

- (void)renderToEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(MetalImageTextureResource *)resource {
#if DEBUG
    renderEncoder.label = NSStringFromClass([self class]);
    [renderEncoder pushDebugGroup:@"MovieWriter Draw"];
#endif
    
    [renderEncoder setRenderPipelineState:_renderTarget.pielineState];
    [renderEncoder setVertexBuffer:_renderTarget.position offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_renderTarget.textureCoord offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:resource.texture.metalTexture atIndex:0];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    
#if DEBUG
    [renderEncoder popDebugGroup];
#endif
}

#pragma mark - Audio Write Process
- (void)audioProcess:(MetalImageAudioResource *)resource time:(CMTime)time {
    // 向前的时间戳一律不接受
    if (CMTimeCompare(_lastAudioTime, time) == 1) {
        return;
    }
    _lastAudioTime = time;
    
    // 还没收到图像前先收到音频
    if (_appendImageFirst && !_haveAppedImage) {
        return;
    }
    
    // 等待上一次写入结束
    while(!self.audioWriterInput.readyForMoreMediaData && !self.audioWriteFinish) {
        NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
        [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
    }
    
    NSError *error = nil;
    switch (self.assetWriter.status) {
        case AVAssetWriterStatusWriting: {
            BOOL suceccsed = [self.audioWriterInput appendSampleBuffer:resource.audioBuffer];
            if (!suceccsed && self.assetWriter.status == AVAssetWriterStatusFailed) {
                error = self.assetWriter.error;
            }
            break;
        }
            
        case AVAssetWriterStatusUnknown:
        case AVAssetWriterStatusCompleted:
        case AVAssetWriterStatusFailed: {
            error = self.assetWriter.error;
            break;
        }
        case AVAssetWriterStatusCancelled: {
            error = kMTMIMovieWriterCancelError;
            break;
        }
        default:
            break;
    }
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completeHandle) {
                self.completeHandle(error);
            }
            self.completeHandle = nil;
        });
    }
}
@end
