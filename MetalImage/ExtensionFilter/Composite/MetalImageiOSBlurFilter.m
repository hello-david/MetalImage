//
//  MetalImageiOSBlurFilter.m
//  MetalImage
//
//  Created by David.Dai on 2019/1/4.
//

#import "MetalImageiOSBlurFilter.h"

@interface MetalImageiOSBlurFilter()
@property (nonatomic, strong) MetalImageLuminanceFilter *luminanceFilter;
@property (nonatomic, strong) MetalImageSaturationFilter *saturationFilter;
@property (nonatomic, strong) MetalImageGaussianBlurFilter *gaussinBlurFiter;
@property (nonatomic, strong) MetalImageSource *source;
@end

@implementation MetalImageiOSBlurFilter

- (instancetype)init {
    if (self = [super init]) {
        _luminanceFilter = [[MetalImageLuminanceFilter alloc] init];
        _saturationFilter = [[MetalImageSaturationFilter alloc] init];
        _gaussinBlurFiter = [[MetalImageGaussianBlurFilter alloc] init];
        _source = [[MetalImageSource alloc] init];
        
        [_saturationFilter addTarget:_gaussinBlurFiter];
        [_gaussinBlurFiter addTarget:_luminanceFilter];
        
        self.blurRadiusInPixels = 4.0;
        self.texelSpacingMultiplier = 2.0;
        self.saturation = 1.0;
        self.luminance = 0.0;
    }
    return self;
}

- (void)receive:(MetalImageResource *)resource withTime:(CMTime)time {
    if (resource.type != MetalImageResourceTypeImage) {
        [self send:resource withTime:time];
        return;
    }
    
    [self.saturationFilter receive:resource withTime:time];
}

- (void)renderToResource:(MetalImageTextureResource *)resource {
    [resource.renderProcess commitRender];
    id <MTLCommandBuffer> commandBuffer1 = [[MetalImageDevice shared].commandQueue commandBuffer];
    [commandBuffer1 enqueue];
    [self.saturationFilter encodeToCommandBuffer:commandBuffer1 withResource:resource];
    [commandBuffer1 commit];
    [commandBuffer1 waitUntilCompleted];
    
    id <MTLCommandBuffer> commandBuffer2 = [[MetalImageDevice shared].commandQueue commandBuffer];
    [commandBuffer2 enqueue];
    [self.gaussinBlurFiter encodeToCommandBuffer:commandBuffer2 withResource:resource];
    [commandBuffer2 commit];
    [commandBuffer2 waitUntilCompleted];
    
    id <MTLCommandBuffer> commandBuffer3 = [[MetalImageDevice shared].commandQueue commandBuffer];
    [commandBuffer3 enqueue];
    [self.luminanceFilter encodeToCommandBuffer:commandBuffer3 withResource:resource];
    [commandBuffer3 commit];
    [commandBuffer3 waitUntilCompleted];
}

#pragma mark - 属性设置
-(void)setBlurRadiusInPixels:(float)blurRadiusInPixels {
    _blurRadiusInPixels = blurRadiusInPixels;
    self.gaussinBlurFiter.blurRadiusInPixels = blurRadiusInPixels;
}

- (void)setSaturation:(float)saturation {
    _saturation = saturation;
    self.saturationFilter.saturation = saturation;
}

- (void)setLuminance:(float)luminance {
    _luminance = luminance;
    self.luminanceFilter.rangeReductionFactor = luminance;
}

- (void)setTexelSpacingMultiplier:(float)texelSpacingMultiplier {
    _texelSpacingMultiplier = texelSpacingMultiplier;
    self.gaussinBlurFiter.texelSpacingMultiplier = texelSpacingMultiplier;
}

#pragma mark - 链路协议
- (void)addTarget:(id<MetalImageTarget>)target {
    [self.source addTarget:target];
    [self.luminanceFilter addTarget:target];
}

- (void)removeTarget:(id<MetalImageTarget>)target {
    [self.source removeTarget:target];
    [self.luminanceFilter removeTarget:target];
}

- (void)removeAllTarget {
    [self.source removeAllTarget];
    [self.luminanceFilter removeAllTarget];
}

- (void)send:(MetalImageResource *)resource withTime:(CMTime)time {
    [self.saturationFilter send:resource withTime:time];
}
@end
