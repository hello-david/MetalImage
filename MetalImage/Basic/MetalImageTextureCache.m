//
//  MetalImageTextureCache.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import "MetalImageTextureCache.h"

#define MetalImageTextureCacheKey(width, height, pixelFormat) [NSString stringWithFormat:@"width:%lud,height:%lud,pixelFormat:%lud",(unsigned long)width, (unsigned long)height, (unsigned long)pixelFormat]
typedef struct {
    NSUInteger width;
    NSUInteger height;
    NSUInteger pixelFormat;
} MetalImageTextureKey;

@interface MetalImageTextureCache()
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray<MetalImageTexture*>*> *textureDic;
@property (nonatomic, strong) NSMutableDictionary <NSString *, MTLTextureDescriptor *> *textureDescDic;
@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, assign) MetalImageTextureKey lastKey;
@property (nonatomic, copy) NSString *lastKeyStr;
@property (nonatomic, strong) dispatch_queue_t cacheQueue;
@end

@implementation MetalImageTextureCache

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        _textureDic = [[NSMutableDictionary alloc] init];
        _textureDescDic = [[NSMutableDictionary alloc] init];
        _cacheQueue = dispatch_queue_create("com.MetalImage.TextureCache", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (MetalImageTexture *)fetchTexture:(CGSize)size pixelFormat:(MTLPixelFormat)pixelFormat {
    __block MetalImageTexture *texture = nil;
    dispatch_sync(self.cacheQueue, ^{
        NSUInteger width = (NSUInteger)size.width;
        NSUInteger height = (NSUInteger)size.height;
        NSString *key = nil;
        
        if (width == self.lastKey.width && height == self.lastKey.height && self.lastKey.pixelFormat == pixelFormat && self.lastKeyStr) {
            key = self.lastKeyStr;
        }
        else {
            key = MetalImageTextureCacheKey(width, height, pixelFormat);
            MetalImageTextureKey lastedKey = {width, height, pixelFormat};
            self.lastKey = lastedKey;
            self.lastKeyStr = key;
        }
        
        NSMutableArray *textureArray = [self.textureDic objectForKey:key];
        if (!textureArray) {
            textureArray = [[NSMutableArray alloc] init];
            [self.textureDic setObject:textureArray forKey:key];
        }
        
        texture = [textureArray lastObject];
        if (texture) {
            [textureArray removeLastObject];
        }
        else {
            MTLTextureDescriptor *textureDesc = [self.textureDescDic objectForKey:key];
            if (!textureDesc) {
                textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:pixelFormat
                                                                                 width:width
                                                                                height:height
                                                                             mipmapped:NO];
                textureDesc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;
                [self.textureDescDic setObject:textureDesc forKey:key];
            }
            
            id<MTLTexture> metalTexture = [self.device newTextureWithDescriptor:textureDesc];
            texture = [[MetalImageTexture alloc] initWithTexture:metalTexture orientation:MetalImagePortrait willCache:YES];
            texture.cacheKey = key;
        }
    });
    
    return texture;
}

- (void)cacheTexture:(MetalImageTexture *)texutre {
    if (!texutre.willCache || !texutre) {
        return;
    }
    
    dispatch_async(self.cacheQueue, ^{
        NSString *key = texutre.cacheKey ? texutre.cacheKey : MetalImageTextureCacheKey(texutre.width, texutre.height, texutre.pixelFormat);
        NSMutableArray *textureArray = [self.textureDic objectForKey:key];
        if (!textureArray) {
            textureArray = [[NSMutableArray alloc] init];
            [self.textureDic setObject:textureArray forKey:key];
        }
        
        if (![textureArray containsObject:texutre]) {
            [textureArray insertObject:texutre atIndex:0];
        }
    });
}

- (void)freeAllTexture {
    dispatch_sync(self.cacheQueue, ^{
        [self.textureDic removeAllObjects];
        [self.textureDescDic removeAllObjects];
        self.lastKeyStr = nil;
    });
}
@end
