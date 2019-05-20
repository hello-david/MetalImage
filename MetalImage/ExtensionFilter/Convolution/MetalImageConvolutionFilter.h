//
//  MetalImageConvolutionFilter.h
//  MetalImage
//
//  Created by David.Dai on 2019/4/1.
//

#import "MetalImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageConvolutionFilter : MetalImageFilter
@property (readonly, nonatomic) NSUInteger kernelHeight;
@property (readonly, nonatomic) NSUInteger kernelWidth;
@property (assign, nonatomic) float bias;

+ (instancetype _Nullable)filterWithKernelWidth:(NSUInteger)kernelWidth
                                   kernelHeight:(NSUInteger)kernelHeight
                                        weights:(const float*)kernelWeights;

+ (NSString *)vertexShaderWithKernelWidth:(NSUInteger)kernelWidth
                             kernelHeight:(NSUInteger)kernelHeight;

+ (NSString *)fragmentShaderWithKernelWidth:(NSUInteger)kernelWidth
                               kernelHeight:(NSUInteger)kernelHeight
                                    weights:(const float *)kernelWeights;
@end

NS_ASSUME_NONNULL_END
