# MetalImage
## 简介
MetalImage是基于Metal框架实现的一套图像滤镜链处理框架。

### 功能
* 目前实现主要的框架(Camera/Picture/MovieWriter/Filter/View等)和基本的滤镜

* 8.0 API还未测试

### 使用说明

1.相机画面分发到视图上
```
self.camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
MetalImageView *view = [[MetalImageView alloc] initWithFrame:CGRectMake(0, 0, 750 / 2, 1334 / 2)];
    
MetalImageFilter *filter = [[MetalImageFilter alloc] init];
[self.camera addTarget:filter];
    
[self.camera startCapture];
[self.view addSubview:view];
```

2.相机拍摄画面分发到视图和录制器上
```
self.camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
MetalImageView *view = [[MetalImageView alloc] initWithFrame:CGRectMake(0, 0, 750 / 2, 1334 / 2)];
MetalImageMovieWriter *movieWriter = [[MetalImageMovieWriter alloc] initWithStorageUrl:outputURL size:CGSizeMake(1080, 640)];
[self.camera addTarget:view];
[self.camera addTarget:movieWriter];
movieWriter.fillMode = MetalImageContentModeScaleAspectFit;
movieWriter.backgroundType = MetalImagContentBackgroundFilter;
movieWriter.backgroundFilter = [[MetalImageiOSBlurFilter alloc] init];
((MetalImageiOSBlurFilter *)movieWriter.backgroundFilter).blurRadiusInPixels = 10.0;
((MetalImageiOSBlurFilter *)movieWriter.backgroundFilter).texelSpacingMultiplier = 2.0;
((MetalImageiOSBlurFilter *)movieWriter.backgroundFilter).saturation = 1.0;
    
[movieWriter startRecording];
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [movieWriter finishRecording];
});
    
[self.camera startCapture];
```

3.图片滤镜处理
```
MetalImageSharpenFilter *sharpen = [[MetalImageSharpenFilter alloc] init];
sharpen.sharpness = 2.0;
[self.picture processImageByFilters:@[sharpen] completion:^(UIImage *processedImage) {
    
}];
```

#### 环境要求
* iOS版本要求: >= 8.0
