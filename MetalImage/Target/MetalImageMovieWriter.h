//
//  MetalImageMovieWriter.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/13.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MetalImageProtocol.h"
#import "MetalImageTarget.h"
#import "MetalImageFilter.h"
#import "MetalImageTextureResource.h"
#import "MetalImageAudioResource.h"

#define kMetalImageMovieWriterCancelError [NSError errorWithDomain:@"MoiveWriterWriterError" code:-9001 userInfo:@{@"message" : @"WriterCanceled"}]

NS_ASSUME_NONNULL_BEGIN
typedef void(^_Nullable MetalImageMovieWriterCompleteHandlle)(NSError *_Nullable error);
typedef void(^_Nullable MetalImageMovieWriterStartHandlle)(NSError *_Nullable error);

@interface MetalImageMovieWriter : NSObject <MetalImageTarget>
@property (nonatomic, assign) MetalImageContentMode fillMode;
@property (nonatomic, assign) MetalImagContentBackground backgroundType;
@property (nonatomic, strong, nullable) id<MetalImageRender> backgroundFilter;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) BOOL haveAudioTrack;

@property (nonatomic, copy) MetalImageMovieWriterCompleteHandlle completeHandle;
@property (nonatomic, copy) MetalImageMovieWriterStartHandlle startHandle;

@property (nonatomic, assign, readonly) AVAssetWriterStatus status;
@property (nonatomic, strong, readonly) NSURL *storageUrl;

- (instancetype)initWithStorageUrl:(NSURL *)storageUrl size:(CGSize)size;

/**
 *  开启录制
 */
- (void)startRecording;

/**
 *  取消录制
 */
- (void)cancelRecording;

/**
 *  结束录制
 */
- (void)finishRecording;
@end

NS_ASSUME_NONNULL_END
