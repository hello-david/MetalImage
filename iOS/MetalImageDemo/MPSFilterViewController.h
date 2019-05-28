//
//  MPSFilterViewController.h
//  MetalImageDemo
//
//  Created by David.Dai on 2019/5/20.
//  Copyright © 2019 David. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MPSFilterType) {
    MPSFilterTypeEdgeDetection,
    MPSFilterTypeGaussianBlur
};

@interface MPSFilterViewController : UIViewController

+ (instancetype)filterWithType:(MPSFilterType)type;

@end

NS_ASSUME_NONNULL_END
