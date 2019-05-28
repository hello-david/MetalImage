//
//  ViewController.m
//  MetalImageDemo
//
//  Created by David.Dai on 2018/11/29.
//  Copyright © 2018 David. All rights reserved.
//

#import "ViewController.h"
#import "BasicViewController.h"
#import "RecordViewController.h"
#import "FilterViewController.h"
#import "MPSFilterViewController.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray *> *dataSource;
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (NSArray<NSArray *> *)dataSource {
    if (!_dataSource) {
        _dataSource = @[@[@"相机/图片显示", @"录制"],
                        @[@"饱和度", @"对比度", @"亮度", @"色调", @"锐化", @"高斯模糊", @"毛玻璃", @"边缘检测"],
                        @[@"边缘检测", @"高斯模糊"]];
    }
    return _dataSource;
}

#pragma mark - 选择列表回调
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"基础功能";
    }
    
    if (section == 1) {
        return @"拓展滤镜效果";
    }
    
    if (section == 2) {
        return @"MPS滤镜效果";
    }
    
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataSource.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource objectAtIndex:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"OptionCell"];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
    cell.textLabel.text = [[self.dataSource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self tableViewOptionEvent:indexPath.row section:indexPath.section];
}

#pragma mark - 选择事件内部逻辑
- (void)tableViewOptionEvent:(NSInteger)index section:(NSInteger)section {
    // 基础功能
    if (section == 0) {
        switch (index) {
            case 0: {
                BasicViewController *vc = [[BasicViewController alloc] initWithNibName:@"BasicViewController" bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
                
            case 1: {
                RecordViewController *vc = [[RecordViewController alloc] initWithNibName:@"RecordViewController" bundle:nil];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
            default:
                break;
        }
    }
    
    // 拓展滤镜
    if (section == 1) {
        id<MetalImageSource, MetalImageTarget, MetalImageRender> filter = nil;
        NSArray *effectPropertyName = nil;
        NSArray *values = nil;
        BOOL usePicture = NO;
        switch (index) {
            case 0: {
                filter = [[MetalImageSaturationFilter alloc] init];
                effectPropertyName = @[@"saturation"];
                FileterNumericalValue value1 = {0.0, 2.0, 1.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 1: {
                filter = [[MetalImageContrastFilter alloc] init];
                effectPropertyName = @[@"contrast"];
                FileterNumericalValue value1 = {0.0, 2.0, 1.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 2: {
                filter = [[MetalImageLuminanceFilter alloc] init];
                effectPropertyName = @[@"rangeReductionFactor"];
                FileterNumericalValue value1 = {-1.0, 1.0, 0.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 3: {
                filter = [[MetalImageHueFilter alloc] init];
                effectPropertyName = @[@"hue"];
                FileterNumericalValue value1 = {-1.0, 1.0, 0.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 4: {
                filter = [[MetalImageSharpenFilter alloc] init];
                effectPropertyName = @[@"sharpness"];
                FileterNumericalValue value1 = {-4.0, 4.0, 0.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 5: {
                filter = [[MetalImageGaussianBlurFilter alloc] init];
                effectPropertyName = @[@"blurRadiusInPixels", @"texelSpacingMultiplier"];
                FileterNumericalValue value1 = {0.0, 8.0, 4.0};
                FileterNumericalValue value2 = {0.0, 15.0, 2.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)],
                           [NSValue value:&value2 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 6: {
                filter = [[MetalImageiOSBlurFilter alloc] init];
                effectPropertyName = @[@"blurRadiusInPixels", @"saturation", @"luminance"];
                FileterNumericalValue value1 = {0.0, 16.0, 8.0};
                FileterNumericalValue value2 = {-1.0, 1.0, 0.0};
                FileterNumericalValue value3 = {-1.0, 1.0, 0.0};
                values = @[[NSValue value:&value1 withObjCType:@encode(FileterNumericalValue)],
                           [NSValue value:&value2 withObjCType:@encode(FileterNumericalValue)],
                           [NSValue value:&value3 withObjCType:@encode(FileterNumericalValue)]];
                break;
            }
            case 7: {
                const float weights[] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                filter = [MetalImageConvolutionFilter filterWithKernelWidth:3 kernelHeight:3 weights:weights];
                usePicture = YES;
                break;
            }
            default:
                break;
        }
        
        if (filter) {
            FilterModel *model = [FilterModel filter:filter effectProperty:effectPropertyName value:values];
            FilterViewController *filterVC = [FilterViewController filterVCWithModel:model];
            filterVC.usePicture = usePicture;
            [self.navigationController pushViewController:filterVC animated:YES];
        }
    }
    
    // MPS滤镜
    if (section == 2) {
        MPSFilterViewController *filterVC = [MPSFilterViewController filterWithType:index];
        [self.navigationController pushViewController:filterVC animated:YES];
    }
}

@end
