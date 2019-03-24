//
//  ViewController.m
//  MetalImageDemo
//
//  Created by David.Dai on 2018/11/29.
//  Copyright © 2018 David. All rights reserved.
//

#import "ViewController.h"
#import "MetalImageCamera.h"
#import "MetalImageView.h"
#import "MetalImageFilter.h"
#import "MetalImageMovieWriter.h"
#import "MetalImageiOSBlurFilter.h"
#import "MetalImageSharpenFilter.h"
#import "MetalImagePicture.h"

@interface ViewController ()
@property (nonatomic, strong) MetalImageCamera *camera;
@property (nonatomic, strong) MetalImagePicture *picture;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    MetalImageView *view = [[MetalImageView alloc] initWithFrame:CGRectMake(0, 0, 750 / 2, 1334 / 2)];
    self.picture = [[MetalImagePicture alloc] initWithImage:[UIImage imageNamed:@"1.jpg"]];
    
//    MetalImageSharpenFilter *sharpen = [[MetalImageSharpenFilter alloc] init];
//    sharpen.sharpness = 2.0;
//    [self.picture processImageByFilters:@[sharpen] completion:^(UIImage *processedImage) {
//
//    }];
    
//    MetalImageFilter *firstFilter = [[MetalImageFilter alloc] init];
//    MetalImageFilter *lastFilter = nil;
//    [self.camera setTarget:firstFilter];
//    for (int i = 0; i < 100; i++) {
//        lastFilter = [[MetalImageFilter alloc] init];
//        [firstFilter setTarget:lastFilter];
//        firstFilter = lastFilter;
//    }
//    [firstFilter setTarget:view];
    
    NSString *videoFileDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *videoFilePath = [videoFileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"video_%d.mp4",0]];
    NSLog(@"videoFilePath = %@",videoFilePath);
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoFilePath];
    [self removeFile:outputURL];

    MetalImageMovieWriter *movieWriter = [[MetalImageMovieWriter alloc] initWithStorageUrl:outputURL size:CGSizeMake(1080, 640)];
    [self.camera setTarget:view];
    [self.camera addAsyncTarget:movieWriter];
    movieWriter.fillMode = kMetalImageContentModeScaleAspectFit;
    movieWriter.backgroundType = kMetalImagContentBackgroundFilter;
    movieWriter.backgroundFilter = [[MetalImageiOSBlurFilter alloc] init];
    ((MetalImageiOSBlurFilter *)movieWriter.backgroundFilter).blurRadiusInPixels = 10.0;
    ((MetalImageiOSBlurFilter *)movieWriter.backgroundFilter).texelSpacingMultiplier = 2.0;
    ((MetalImageiOSBlurFilter *)movieWriter.backgroundFilter).saturation = 1.0;

    [movieWriter startRecording];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [movieWriter finishRecording];
    });
    
    [self.camera startCapture];
    [self.view addSubview:view];
}

- (void)removeFile:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [fileURL path];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        [fileManager removeItemAtPath:filePath error:&error];
    }
}
@end
