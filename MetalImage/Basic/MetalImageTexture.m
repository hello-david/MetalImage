//
//  MetalImageTexture.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import "MetalImageTexture.h"

@interface MetalImageTexture()
@property (nonatomic, assign) BOOL willCache;
@end

@implementation MetalImageTexture

- (instancetype)initWithTexture:(id<MTLTexture>)texutre
                    orientation:(MetalImageOrientation)orientation
                      willCache:(BOOL)willCache {
    if (self = [super init]) {
        _metalTexture = texutre;
        _orientation = orientation;
        _willCache = willCache;
    }
    return self;
}

- (NSUInteger)width {
    return _metalTexture.width;
}

- (NSUInteger)height {
    return _metalTexture.height;
}

- (CGSize)size {
    return CGSizeMake(_metalTexture.width, _metalTexture.height);
}

- (MTLPixelFormat)pixelFormat {
    return _metalTexture.pixelFormat;
}

- (MetalImageCoordinate)textureCoordinatesToOrientation:(MetalImageOrientation)orientation {
    MetalImageRotationMode rotationMode = kMetalImageNoRotation;
    if (self.orientation == orientation) {
        rotationMode = kMetalImageNoRotation;
    }
    else if ((self.orientation == kMetalImagePortrait && orientation == kMetalImagePortraitUpsideDown) ||
             (self.orientation == kMetalImagePortraitUpsideDown && orientation == kMetalImagePortrait) ||
             (self.orientation == kMetalImageLandscapeLeft && orientation == kMetalImageLandscapeRight)||
             (self.orientation == kMetalImageLandscapeRight && orientation == kMetalImageLandscapeLeft)) {
        rotationMode = kMetalImageRotate180;
    }
    else if ((self.orientation == kMetalImagePortrait && orientation == kMetalImageLandscapeLeft) ||
             (self.orientation == kMetalImageLandscapeRight && orientation == kMetalImagePortrait) ||
             (self.orientation == kMetalImageLandscapeLeft && orientation == kMetalImagePortraitUpsideDown) ||
             (self.orientation == kMetalImagePortraitUpsideDown && orientation == kMetalImageLandscapeRight)) {
        rotationMode = kMetalImageRotateCounterclockwise;
    }
    else if ((self.orientation == kMetalImageLandscapeLeft && orientation == kMetalImagePortrait) ||
             (self.orientation == kMetalImagePortrait && orientation == kMetalImageLandscapeRight) ||
             (self.orientation == kMetalImagePortraitUpsideDown && orientation == kMetalImageLandscapeLeft) ||
             (self.orientation == kMetalImageLandscapeRight && orientation == kMetalImagePortraitUpsideDown)) {
        rotationMode = kMetalImageRotateClockwise;
    }
    
    /**
     *  在Metal/GL中绘制时纹理坐标系和顶点坐标系是x轴对称的
     *  因为内存中图像读取上从上到下从左至右，而图像的坐标系是从下到上从左至右
     *  这里直接进行转换
     */
    static const MetalImageCoordinate noRotationCoordinates = {0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0f, 0.0};
    static const MetalImageCoordinate rotateClockwiseCoordinates = {1.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};
    static const MetalImageCoordinate rotateCounterclockwiseCoordinates = {0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f, 1.0f, 1.0f};
    static const MetalImageCoordinate rotate180Coordinates = {1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 0.0f, 1.0f};
    static const MetalImageCoordinate flipHorizontallyCoordinates = {1.0f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f};
    static const MetalImageCoordinate flipVerticallyCoordinates = {0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f};
    static const MetalImageCoordinate rotateClockwiseAndFlipVerticallyCoordinates = {1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f};
    static const MetalImageCoordinate rotateClockwiseAndFlipHorizontallyCoordinates = {0.0f, 1.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.0f};
    
    switch (rotationMode) {
        case kMetalImageNoRotation:
            return noRotationCoordinates;
            
        case kMetalImageRotateCounterclockwise:
            return rotateCounterclockwiseCoordinates;
            
        case kMetalImageRotateClockwise:
            return rotateClockwiseCoordinates;
            
        case kMetalImageRotate180:
            return rotate180Coordinates;
            
        case kMetalImageFlipHorizonal:
            return flipHorizontallyCoordinates;
            
        case kMetalImageFlipVertically:
            return flipVerticallyCoordinates;
            
        case kMetalImageRotateClockwiseAndFlipVertically:
            return rotateClockwiseAndFlipVerticallyCoordinates;
            
        case kMetalImageRotateClockwiseAndFlipHorizontally:
            return rotateClockwiseAndFlipHorizontallyCoordinates;
            
        default:
            return noRotationCoordinates;
            break;
    }
}

- (MetalImageCoordinate)texturePositionToSize:(CGSize)targetSize contentMode:(MetalImageContentMode)contentMode {
    CGSize texturePortraitSize = CGSizeZero;
    if (self.orientation == kMetalImagePortrait || self.orientation == kMetalImagePortraitUpsideDown) {
        texturePortraitSize = CGSizeMake(self.width, self.height);
    }
    else {
        texturePortraitSize = CGSizeMake(self.height, self.width);
    }
    
    float heightScaling, widthScaling;
    CGSize insetSize = [self makeRectWithAspectRatio:texturePortraitSize destSize:targetSize].size;
    MetalImageCoordinate position;
    switch (contentMode) {
        case kMetalImageContentModeScaleToFill:
            widthScaling = 1.0;
            heightScaling = 1.0;
            break;
            
        case kMetalImageContentModeScaleAspectFit:
            widthScaling = insetSize.width / targetSize.width;
            heightScaling = insetSize.height / targetSize.height;
            break;
            
        case kMetalImageContentModeScaleAspectFill:
            widthScaling = targetSize.height / insetSize.height;
            heightScaling = targetSize.width / insetSize.width;
            break;
            
        default:
            break;
    }
    
    position.bottomLeftX  = -widthScaling;
    position.bottomLeftY  = -heightScaling;
    
    position.bottomRightX = widthScaling;
    position.bottomRightY = -heightScaling;
    
    position.topLeftX     = -widthScaling;
    position.topLeftY     = heightScaling;
    
    position.topRightX    = widthScaling;
    position.topRightY    = heightScaling;
    
    return position;
}

- (CGRect)makeRectWithAspectRatio:(CGSize)srcSize destSize:(CGSize)destSize {
    float srcAspectRatio = srcSize.width / srcSize.height;
    float destApectRatio = destSize.width / destSize.height;
    
    float resultHeight, resultWidth;
    if (srcAspectRatio > destApectRatio) {
        resultWidth = destSize.width;
        resultHeight = srcSize.height / (srcSize.width / resultWidth);
    }else {
        resultHeight = destSize.height;
        resultWidth = srcSize.width / (srcSize.height / resultHeight);
    }
    
    return CGRectMake((destSize.width - resultWidth) / 2, (destSize.height - resultHeight) / 2, resultWidth, resultHeight);
}

- (UIImage *)imageFromTexture {
    return [[self class] imageFromMTLTexture:self.metalTexture];
}

- (void)replaceTexture:(id<MTLTexture>)texture {
    if (!texture) {
        return;
    }
    
    [[self class] texutreDataProviderProcess:texture process:^(CGDataProviderRef provider, CGSize imageSize, NSUInteger bytesPerRow) {
        CFDataRef data = CGDataProviderCopyData(provider);
        [self.metalTexture replaceRegion:MTLRegionMake2D(0, 0, imageSize.width, imageSize.height)
                             mipmapLevel:0
                               withBytes:CFDataGetBytePtr(data)
                             bytesPerRow:4 * imageSize.width];
        CFRelease(data);
    }];
}

static void MetalImageReleaseDataCallback(void *info, const void *data, size_t size) {
    free((void *)data);
}

+ (UIImage *)imageFromMTLTexture:(id<MTLTexture>)texture {
    NSAssert([texture pixelFormat] == MTLPixelFormatBGRA8Unorm, @"Pixel format of texture must be MTLPixelFormatBGRA8Unorm to create UIImage");
    
    __block UIImage *image = nil;
    [[self class] texutreDataProviderProcess:texture process:^(CGDataProviderRef provider, CGSize imageSize, NSUInteger bytesPerRow) {
        int bitsPerComponent = 8;
        int bitsPerPixel = 32;
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;// BGRA
//        kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst//ARGB
        
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        CGImageRef imageRef = CGImageCreate(imageSize.width,
                                            imageSize.height,
                                            bitsPerComponent,
                                            bitsPerPixel,
                                            bytesPerRow,
                                            colorSpaceRef,
                                            bitmapInfo,
                                            provider,
                                            NULL,
                                            false,
                                            renderingIntent);
        
        image = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationDownMirrored];
        
        CFRelease(colorSpaceRef);
        CFRelease(imageRef);
    }];
    
    return image;
}

+ (id<MTLTexture>)textureFromImage:(UIImage *)image device:(id<MTLDevice>)device {
    CGSize imageSize = image.size;
    if (!imageSize.width || !imageSize.height) {
        return nil;
    }
    
    CGImageRef imageRef = image.CGImage;
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    
    MTLPixelFormat format = MTLPixelFormatBGRA8Unorm;
    MTLTextureDescriptor *textureDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
                                                                                           width:imageSize.width
                                                                                          height:imageSize.height
                                                                                       mipmapped:NO];
    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDesc];
    
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    [texture replaceRegion:MTLRegionMake2D(0, 0, imageSize.width, imageSize.height)
               mipmapLevel:0
                 withBytes:CFDataGetBytePtr(data)
               bytesPerRow:4 * imageSize.width];
    CFRelease(data);
    
    return texture;
}

+ (void)textureCVPixelBufferProcess:(id<MTLTexture>)texture process:(void(^)(CVPixelBufferRef pixelBuffer))process {
    if (!texture) {
        return ;
    }
    
    NSAssert([texture pixelFormat] == MTLPixelFormatBGRA8Unorm, @"Pixel format of texture must be MTLPixelFormatBGRA8Unorm to create Pixel");
    
    __block CVPixelBufferRef pixelBuffer = NULL;
    [[self class] texutreDataProviderProcess:texture process:^(CGDataProviderRef provider, CGSize imageSize, NSUInteger bytesPerRow) {
        CFDataRef data = CGDataProviderCopyData(provider);
        CVReturn ret = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, imageSize.width, imageSize.height,
                                                    kCVPixelFormatType_32BGRA,
                                                    (void *)CFDataGetBytePtr(data),
                                                    bytesPerRow, nil, nil, nil,
                                                    &pixelBuffer);
        if (ret != 0) {
            NSLog(@"%s, 转换出错",__func__);
            pixelBuffer = NULL;
        }
        
        if (process) {
            process(pixelBuffer);
        }
        
        CVPixelBufferRelease(pixelBuffer);
        CFRelease(data);
    }];
}

+ (void)texutreDataProviderProcess:(id<MTLTexture>)texture process:(void(^)(CGDataProviderRef provider, CGSize imageSize, NSUInteger bytesPerRow))process {
    @autoreleasepool {
        CGSize imageSize = CGSizeMake([texture width], [texture height]);
        NSUInteger bytesPerRow = imageSize.width * 4;
        size_t imageByteCount = imageSize.width * imageSize.height * 4;
        void *imageBytes = malloc(imageByteCount);
        MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
        
        [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imageBytes, imageByteCount, MetalImageReleaseDataCallback);
        
        if (process) {
            process(provider, imageSize, bytesPerRow);
        }
        
        CFRelease(provider);
    }
}
@end
