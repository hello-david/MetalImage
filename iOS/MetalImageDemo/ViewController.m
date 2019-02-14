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

@interface ViewController ()
@property (nonatomic, strong) MetalImageCamera *camera;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    MetalImageView *view = [[MetalImageView alloc] initWithFrame:CGRectMake(0, 0, 750 / 2, 1334 / 2)];
    
    MetalImageFilter *firstFilter = [[MetalImageFilter alloc] init];
    MetalImageFilter *lastFilter = nil;
    [self.camera setTarget:firstFilter];
    for (int i = 0; i < 100; i++) {
        lastFilter = [[MetalImageFilter alloc] init];
        [firstFilter setTarget:lastFilter];
        firstFilter = lastFilter;
    }
    [firstFilter setTarget:view];
    
    [self.camera startCapture];
    [self.view addSubview:view];
}

@end
