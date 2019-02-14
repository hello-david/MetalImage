//
//  MetalImageTarget.h
//  MetalImage
//
//  Created by David.Dai on 2019/1/3.
//

#import <Foundation/Foundation.h>
#import "MetalImageDevice.h"
#import "MetalImageTexture.h"
#import "MetalImageTextureResource.h"

typedef struct {
    CGSize textureSize;
    CGSize targetSize;
    MetalImageOrientation textureOrientation;
    MetalImageContentMode fillMode;
} MetalImageBufferReuseInfo;

@interface MetalImageTarget : NSObject

@property (nonatomic, assign) MetalImageContentMode fillMode;
@property (nonatomic, strong) id<MTLRenderPipelineState> pielineState;
@property (nonatomic, strong) id<MTLBuffer> position;
@property (nonatomic, strong) id<MTLBuffer> textureCoord;
@property (nonatomic, assign) MetalImageBufferReuseInfo bufferReuseInfo;

- (instancetype)initWithDefaultLibraryWithVertex:(NSString *)vertexFunctionName
                                        fragment:(NSString *)fragmentFunctionName;

- (void)updateBufferIfNeed:(MetalImageTexture *)texture targetSize:(CGSize)targetSize;
@end
