//
//  MetalImageView.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import <UIKit/UIKit.h>
#import "MetalImageProtocol.h"
#import "MetalImageTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageView : UIView <MetalImageTarget>
@property (nonatomic, assign) MetalImageContentMode fillMode;
@end

NS_ASSUME_NONNULL_END
