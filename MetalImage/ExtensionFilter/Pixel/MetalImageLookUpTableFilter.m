//
//  MetalImageLookUpTableFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/7/4.
//

#import "MetalImageLookUpTableFilter.h"

@interface MetalImageLookUpTableFilter()

@end

@implementation MetalImageLookUpTableFilter

- (void)renderToCommandEncoder:(id<MTLRenderCommandEncoder>)renderEncoder withResource:(nonnull MetalImageResource *)resource {
    if (MetalImageResourceTypeImage != resource.type) {
        return;
    }
    
}

@end
