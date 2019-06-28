//
//  NSBundle+MetalImageBundle.h
//  MetalImage
//
//  Created by David.Dai on 2019/6/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle(MetalImageBundle)
+ (NSBundle *)metalImage_bundleWithBundleName:(NSString *)bundleName;
@end

NS_ASSUME_NONNULL_END
