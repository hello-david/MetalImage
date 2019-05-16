//
//  FilterViewController.m
//  MetalImageDemo
//
//  Created by David.Dai on 2019/5/13.
//  Copyright © 2019 David. All rights reserved.
//

#import "FilterViewController.h"
@interface FilterModel()
@property (nonatomic, strong) NSArray<NSString *> *propertyName;
@property (nonatomic, strong) NSArray<NSValue *> *value;
@end

@implementation FilterModel
+ (instancetype)filter:(id<MetalImageSource,MetalImageTarget,MetalImageRender>)filter
        effectProperty:(NSArray<NSString *> *)propertyName
                 value:(NSArray<NSValue *> *)value {
    FilterModel *model = [[FilterModel alloc] init];
    model.filter = filter;
    model.propertyName = propertyName;
    model.value = value;
    return model;
}
@end


@interface FilterViewController ()
@property (weak, nonatomic) IBOutlet MetalImageView *firstFrameView;
@property (weak, nonatomic) IBOutlet UISlider *firstSlider;
@property (weak, nonatomic) IBOutlet UISlider *secondSlider;
@property (weak, nonatomic) IBOutlet UISlider *thirdSlider;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdLabel;

@property (nonatomic, strong) MetalImageCamera *camera;
@property (nonatomic, strong) FilterModel *filterModel;
@end

@implementation FilterViewController

+ (instancetype)filterVCWithModel:(FilterModel *)filterModel {
    FilterViewController *vc = [[FilterViewController alloc] initWithNibName:@"FilterViewController" bundle:nil];
    vc.filterModel = filterModel;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.camera addTarget:(id<MetalImageTarget>)self.filterModel.filter];
    [self.filterModel.filter addTarget:self.firstFrameView];
    [self.camera startCapture];
    
    for (NSInteger index = 0; index < self.filterModel.propertyName.count; index ++) {
        FileterNumericalValue value;
        [self.filterModel.value[index] getValue:&value];
        
        if (index == 0) {
            self.firstSlider.maximumValue = value.max;
            self.firstSlider.minimumValue = value.min;
            self.firstSlider.value = value.current;
            self.firstLabel.text = self.filterModel.propertyName[index];
        }
        
        if (index == 1) {
            self.secondSlider.hidden = NO;
            self.secondLabel.hidden = NO;
            self.secondLabel.text = self.filterModel.propertyName[index];
            self.secondSlider.maximumValue = value.max;
            self.secondSlider.minimumValue = value.min;
            self.secondSlider.value = value.current;
        }
        
        if (index == 2) {
            self.thirdSlider.hidden = NO;
            self.thirdLabel.hidden = NO;
            self.thirdLabel.text = self.filterModel.propertyName[index];
            self.thirdSlider.maximumValue = value.max;
            self.thirdSlider.minimumValue = value.min;
            self.thirdSlider.value = value.current;
        }
    }
}

- (IBAction)sliderValueChange:(UISlider *)sender {
    if (sender == self.firstSlider) {
        [(NSObject *)self.filterModel.filter setValue:@(sender.value) forKey:self.filterModel.propertyName[0]];
    }
    
    if (sender == self.secondSlider) {
        [(NSObject *)self.filterModel.filter setValue:@(sender.value) forKey:self.filterModel.propertyName[1]];
    }
    
    if (sender == self.thirdSlider) {
        [(NSObject *)self.filterModel.filter setValue:@(sender.value) forKey:self.filterModel.propertyName[2]];
    }
}

- (MetalImageCamera *)camera {
    if (!_camera) {
        _camera = [[MetalImageCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    }
    return _camera;
}
@end
