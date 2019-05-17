//
//  MetalImageTextureResource.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/27.
//

#import "MetalImageTextureResource.h"

@interface MetalImageTextureResource ()
@property (nonatomic, strong) MetalImageRenderProcess *renderProcess;
@end

@implementation MetalImageTextureResource
- (instancetype)init {
    if (self = [super init]) {
        self.type = MetalImageResourceTypeImage;
    }
    return self;
}

- (instancetype)initWithTexture:(MetalImageTexture *)texture {
    if (self = [super init]) {
        self.type = MetalImageResourceTypeImage;
        self.renderProcess = [[MetalImageRenderProcess alloc] initWithTexture:texture];
    }
    return self;
}

- (MetalImageTexture *)texture {
    return self.renderProcess.texture;
}

- (MetalImageResource *)newResourceFromSelf {
    // 拷贝之前先提交之前的渲染
    [self.renderProcess commitRender];
    
    // 拷贝当前的纹理
    __block MetalImageTextureResource *newResource = nil;
    @autoreleasepool {
        MetalImageTexture *copyTexture = [[MetalImageDevice shared].textureCache fetchTexture:self.texture.size
                                                                                  pixelFormat:self.texture.metalTexture.pixelFormat];
        copyTexture.orientation = self.texture.orientation;
        newResource = [[MetalImageTextureResource alloc] initWithTexture:copyTexture];
        [copyTexture replaceTexture:self.texture.metalTexture];
    }
    
    return newResource;
}
@end
