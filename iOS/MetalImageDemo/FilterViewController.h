//
//  FilterViewController.h
//  MetalImageDemo
//
//  Created by David.Dai on 2019/5/13.
//  Copyright © 2019 David. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MetalImageProtocol.h"

#import "MetalImageView.h"
#import "MetalImageCamera.h"
#import "MetalImagePicture.h"

#import "MetalImageContrastFilter.h"
#import "MetalImageHueFilter.h"
#import "MetalImageSaturationFilter.h"
#import "MetalImageLuminanceFilter.h"
#import "MetalImageLookUpTableFilter.h"

#import "MetalImageSharpenFilter.h"
#import "MetalImageGaussianBlurFilter.h"
#import "MetalImageConvolutionFilter.h"

#import "MetalImageiOSBlurFilter.h"
#import "MetalImageCropFilter.h"

NS_ASSUME_NONNULL_BEGIN
typedef struct {
    float min;
    float max;
    float current;
} FileterNumericalValue;

@interface FilterModel : NSObject
@property (nonatomic, strong, readonly) NSArray<NSString *> *propertyName;
@property (nonatomic, strong, readonly) NSArray<NSValue *> *value;
@property (nonatomic, strong) id<MetalImageSource, MetalImageTarget, MetalImageRender> filter;

+ (instancetype)filter:(id<MetalImageSource, MetalImageTarget, MetalImageRender>)filter
        effectProperty:(NSArray <NSString *> *)propertyName
                 value:(NSArray <NSValue *> *)value;
@end

@interface FilterViewController : UIViewController
@property (nonatomic, assign) BOOL usePicture;
+ (instancetype)filterVCWithModel:(FilterModel *)filterModel;
@end

NS_ASSUME_NONNULL_END
