//
//  RecordViewController.m
//  MetalImageDemo
//
//  Created by David.Dai on 2019/5/13.
//  Copyright © 2019 David. All rights reserved.
//

#import "RecordViewController.h"
#import "MetalImageView.h"
#import "MetalImageCamera.h"
#import "MetalImageMovieWriter.h"
#import "MetalImageiOSBlurFilter.h"

@interface RecordViewController ()
@property (weak, nonatomic) IBOutlet UIButton *startRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordBtn;
@property (weak, nonatomic) IBOutlet MetalImageView *frameView;
@property (nonatomic, strong) MetalImageCamera *camera;
@property (nonatomic, strong) MetalImageMovieWriter *movieWriter;
@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.camera setTarget:self.frameView];
    self.movieWriter.fillMode = kMetalImageContentModeScaleAspectFit;
    [self.camera startCapture];
    self.startRecordBtn.enabled = YES;
    self.stopRecordBtn.enabled = NO;
}

- (IBAction)actionStart:(id)sender {
    [self.camera addAsyncTarget:self.movieWriter];
    [self.movieWriter startRecording];
    self.startRecordBtn.enabled = NO;
    self.stopRecordBtn.enabled = YES;
}

- (IBAction)actionStop:(id)sender {
    [self.movieWriter finishRecording];
    [self.camera removeTarget:self.movieWriter];
    self.movieWriter = nil;
    self.startRecordBtn.enabled = YES;
    self.stopRecordBtn.enabled = NO;
}

- (MetalImageCamera *)camera {
    if (!_camera) {
        _camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPresetMedium cameraPosition:AVCaptureDevicePositionBack];
    }
    return _camera;
}

- (MetalImageMovieWriter *)movieWriter {
    if (!_movieWriter) {
        NSString *videoFileDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString *videoFilePath = [videoFileDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"video_%d.mp4",0]];
        NSLog(@"videoFilePath = %@",videoFilePath);
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:videoFilePath];
        [self removeFile:outputURL];
        
        _movieWriter = [[MetalImageMovieWriter alloc] initWithStorageUrl:outputURL size:CGSizeMake(1080, 640)];
        _movieWriter.fillMode = kMetalImageContentModeScaleAspectFit;
    }
    return _movieWriter;
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
