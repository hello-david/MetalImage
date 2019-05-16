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
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet MetalImageView *frameView;
@property (nonatomic, strong) MetalImageCamera *camera;
@property (nonatomic, strong) MetalImageMovieWriter *movieWriter;
@end

@implementation RecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.camera addTarget:self.frameView];
    [self.camera startCapture];
}

- (IBAction)actionRecord:(id)sender {
    if ([sender isSelected]) {
        if (self.movieWriter.status == AVAssetWriterStatusWriting) {
            [self.movieWriter finishRecording];
            [self.camera removeTarget:self.movieWriter];
            self.movieWriter = nil;
        }
        
        [self.recordBtn setTitle:@"开始录制" forState:UIControlStateNormal];
        [sender setSelected:NO];
    }
    else {
        if (self.movieWriter.status != AVAssetWriterStatusWriting) {
            [self.camera addTarget:self.movieWriter];
            [self.movieWriter startRecording];
        }
        
        [self.recordBtn setTitle:@"停止录制" forState:UIControlStateNormal];
        [sender setSelected:YES];
    }
}

- (MetalImageCamera *)camera {
    if (!_camera) {
        _camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
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
        _movieWriter.fillMode = MetalImageContentModeScaleAspectFit;
        _movieWriter.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
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
