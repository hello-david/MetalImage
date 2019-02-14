//
//  MetalImageView.h
//  MetalImage
//
//  Created by David.Dai on 2018/11/29.
//

#import <UIKit/UIKit.h>
#import "MetalImageProtocol.h"
#import "MetalImageTarget.h"

@interface MetalImageView : UIView <MetalImageTarget>
@property (nonatomic, assign) MetalImageContentMode fillMode;
@end
