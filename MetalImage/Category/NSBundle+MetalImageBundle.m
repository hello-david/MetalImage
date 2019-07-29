//
//  NSBundle+MetalImageBundle.m
//  MetalImage
//
//  Created by David.Dai on 2019/6/28.
//

#import "NSBundle+MetalImageBundle.h"

@implementation NSBundle(MetalImageBundle)
+ (NSBundle *)metalImage_bundleWithName:(NSString *)bundleName {
    if (!bundleName) {
        return nil;
    }
    
    if ([bundleName containsString:@".bundle"]) {
        bundleName = [bundleName componentsSeparatedByString:@".bundle"].firstObject;
    }
    
    // 兼容cocoapods framework方式引入的时候Bundle地址
    NSURL *associateBundleURL = [[NSBundle mainBundle] URLForResource:bundleName withExtension:@"bundle"];
    if (!associateBundleURL) {
        associateBundleURL = [[NSBundle mainBundle] URLForResource:@"Frameworks" withExtension:nil];
        associateBundleURL = [associateBundleURL URLByAppendingPathComponent:@"MetalImage"];
        associateBundleURL = [associateBundleURL URLByAppendingPathExtension:@"framework"];
        NSBundle *associateBunle = [NSBundle bundleWithURL:associateBundleURL];
        associateBundleURL = [associateBunle URLForResource:bundleName withExtension:@"bundle"];
    }
    
    return associateBundleURL ? [NSBundle bundleWithURL:associateBundleURL] : nil;
}
@end
