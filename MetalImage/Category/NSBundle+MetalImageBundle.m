//
//  NSBundle+MetalImageBundle.m
//  MetalImage
//
//  Created by David.Dai on 2019/6/28.
//

#import "NSBundle+MetalImageBundle.h"

@implementation NSBundle(MetalImageBundle)
+ (NSBundle *)metalImage_bundleWithBundleName:(NSString *)bundleName {
    if (!bundleName) {
        return nil;
    }
    
    if ([bundleName containsString:@".bundle"]) {
        bundleName = [bundleName componentsSeparatedByString:@".bundle"].firstObject;
    }
    
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
