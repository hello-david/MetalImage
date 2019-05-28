//
//  MPSFilterViewController.m
//  MetalImageDemo
//
//  Created by David.Dai on 2019/5/20.
//  Copyright © 2019 David. All rights reserved.
//

#import "MPSFilterViewController.h"
#import <Metal/MTLDevice.h>
#import <Metal/MTLCommandQueue.h>
#import <Metal/MTLPixelFormat.h>
#import <MetalKit/MTKTextureLoader.h>
#import "MetalImageTexture.h"

@interface MPSFilterViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) MPSFilterType type;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLTexture> sourceTexture;
@property (nonatomic, strong) id<MTLTexture> destinationTexture;

@property (nonatomic, strong) MPSKernel *mpsFilter;
@end

@implementation MPSFilterViewController

+ (instancetype)filterWithType:(MPSFilterType)type {
    MPSFilterViewController *vc = [[MPSFilterViewController alloc] init];
    vc.type = type;
    return vc;
}

- (id<MTLDevice>)device {
    if (!_device) {
        _device = MTLCreateSystemDefaultDevice();
    }
    return _device;
}

- (id<MTLCommandQueue>)commandQueue {
    if (!_commandQueue) {
        _commandQueue = [self.device newCommandQueue];
    }
    return _commandQueue;
}

- (id<MTLTexture>)sourceTexture {
    if (!_sourceTexture) {
        MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.device];
        _sourceTexture = [textureLoader newTextureWithCGImage:[[UIImage imageNamed:@"1.jpg"] CGImage]
                                                      options:NULL
                                                        error:nil];
    }
    return _sourceTexture;
}

- (id<MTLTexture>)destinationTexture {
    if (!_destinationTexture) {
        MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:self.sourceTexture.pixelFormat
                                                                                               width:self.sourceTexture.width
                                                                                              height:self.sourceTexture.height
                                                                                           mipmapped:NO];
        textureDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
        _destinationTexture = [self.device newTextureWithDescriptor:textureDesc];
    }
    return _destinationTexture;
}

- (MPSKernel *)mpsFilter {
    if (!_mpsFilter) {
        switch (self.type) {
            case MPSFilterTypeEdgeDetection: {
                const float weights[] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                MPSImageConvolution *convolition = [[MPSImageConvolution alloc] initWithDevice:self.device
                                                                                   kernelWidth:3
                                                                                  kernelHeight:3
                                                                                       weights:weights];
                _mpsFilter = convolition;
                break;
            }
            case MPSFilterTypeGaussianBlur: {
                MPSImageGaussianBlur *gaussian = [[MPSImageGaussianBlur alloc] initWithDevice:self.device sigma:10];
                _mpsFilter = gaussian;
                break;
            }
                
            default:
                break;
        }
    }
    return _mpsFilter;
}

#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self processImageWithType:self.type];
}

- (void)processImageWithType:(MPSFilterType)type {
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    [commandBuffer enqueue];
    
    switch (type) {
        case MPSFilterTypeEdgeDetection: {
            [(MPSImageConvolution *)self.mpsFilter encodeToCommandBuffer:commandBuffer
                                                           sourceTexture:self.sourceTexture
                                                      destinationTexture:self.destinationTexture];
            break;
        }
        case MPSFilterTypeGaussianBlur: {
            [(MPSImageGaussianBlur *)self.mpsFilter encodeToCommandBuffer:commandBuffer
                                                            sourceTexture:self.sourceTexture
                                                       destinationTexture:self.destinationTexture];
            break;
        }
            
        default:
            break;
    }
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull buffer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageView.image = [MetalImageTexture imageFromMTLTexture:self.destinationTexture];
        });
    }];
    [commandBuffer commit];
}

@end
