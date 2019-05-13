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
                        @[@"饱和度", @"对比度", @"亮度", @"色调", @"锐化", @"高斯模糊", @"浮雕化", @"边缘检测", @"裁剪", @"毛玻璃"],
                        @[@""]];
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
        
    }
    
    // MPS滤镜
    if (section == 2) {
        
    }
}

@end
