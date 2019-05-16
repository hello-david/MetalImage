//
//  BasicViewController.m
//  MetalImageDemo
//
//  Created by David.Dai on 2019/5/13.
//  Copyright © 2019 David. All rights reserved.
//

#import "BasicViewController.h"
#import "MetalImageView.h"
#import "MetalImageCamera.h"
#import "MetalImagePicture.h"

@interface BasicViewController ()
@property (weak, nonatomic) IBOutlet MetalImageView *firstFrameView;
@property (weak, nonatomic) IBOutlet MetalImageView *secondFrameView;
@property (weak, nonatomic) IBOutlet MetalImageView *thirdFrameView;

@property (nonatomic, strong) MetalImageCamera *camera;
@property (nonatomic, strong) MetalImagePicture *picture;
@end

@implementation BasicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.secondFrameView.fillMode = MetalImageContentModeScaleAspectFit;
    
    [self.camera addTarget:self.firstFrameView];
    [self.camera addTarget:self.secondFrameView];
    [self.camera startCapture];
    
    [self.picture addTarget:self.thirdFrameView];
    [self.picture processImage];
}

- (MetalImageCamera *)camera {
    if (!_camera) {
        _camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPresetMedium cameraPosition:AVCaptureDevicePositionBack];
    }
    return _camera;
}

- (MetalImagePicture *)picture {
    if (!_picture) {
        _picture = [[MetalImagePicture alloc] initWithImage:[UIImage imageNamed:@"1.jpg"]];
    }
    return _picture;
}

@end
