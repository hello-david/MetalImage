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

#define kMTMIMovieWriterCancelError [NSError errorWithDomain:@"MoiveWriterWriterError" code:-9001 userInfo:@{@"message" : @"WriterCanceled"}]

typedef void(^MetalImageMovieWriterCompleteHandlle)(NSError *error);
typedef void(^MetalImageMovieWriterStartHandlle)(NSError *error);

@interface MetalImageMovieWriter : NSObject <MetalImageTarget>
@property (nonatomic, assign) MetalImageContentMode fillMode;
@property (nonatomic, assign) MetalImagContentBackground backgroundType;
@property (nonatomic, strong) UIColor *backgroudColor;
@property (nonatomic, assign) BOOL haveAudioTrack;

@property (nonatomic, strong, readonly) NSURL *storageUrl;
@property (nonatomic, copy) MetalImageMovieWriterCompleteHandlle completeHandle;
@property (nonatomic, copy) MetalImageMovieWriterStartHandlle startHandle;

- (instancetype)init __attribute__((deprecated("此方法已弃用,请使用initWithStorageUrl:size:方法")));
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
