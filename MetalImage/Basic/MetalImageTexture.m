//
//  MetalImageTexture.m
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import "MetalImageTexture.h"

@interface MetalImageTexture()
@property (nonatomic, assign) BOOL willCache;
@property (nonatomic, assign) MTLPixelFormat pixelFormat;
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
    MetalImageRotationMode rotationMode = MetalImageNoRotation;
    if (self.orientation == orientation) {
        rotationMode = MetalImageNoRotation;
    }
    else if ((self.orientation == MetalImagePortrait && orientation == MetalImagePortraitUpsideDown) ||
             (self.orientation == MetalImagePortraitUpsideDown && orientation == MetalImagePortrait) ||
             (self.orientation == MetalImageLandscapeLeft && orientation == MetalImageLandscapeRight)||
             (self.orientation == MetalImageLandscapeRight && orientation == MetalImageLandscapeLeft)) {
        rotationMode = MetalImageRotate180;
    }
    else if ((self.orientation == MetalImagePortrait && orientation == MetalImageLandscapeLeft) ||
             (self.orientation == MetalImageLandscapeRight && orientation == MetalImagePortrait) ||
             (self.orientation == MetalImageLandscapeLeft && orientation == MetalImagePortraitUpsideDown) ||
             (self.orientation == MetalImagePortraitUpsideDown && orientation == MetalImageLandscapeRight)) {
        rotationMode = MetalImageRotateCounterclockwise;
    }
    else if ((self.orientation == MetalImageLandscapeLeft && orientation == MetalImagePortrait) ||
             (self.orientation == MetalImagePortrait && orientation == MetalImageLandscapeRight) ||
             (self.orientation == MetalImagePortraitUpsideDown && orientation == MetalImageLandscapeLeft) ||
             (self.orientation == MetalImageLandscapeRight && orientation == MetalImagePortraitUpsideDown)) {
        rotationMode = MetalImageRotateClockwise;
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
        case MetalImageNoRotation:
            return noRotationCoordinates;
            
        case MetalImageRotateCounterclockwise:
            return rotateCounterclockwiseCoordinates;
            
        case MetalImageRotateClockwise:
            return rotateClockwiseCoordinates;
            
        case MetalImageRotate180:
            return rotate180Coordinates;
            
        case MetalImageFlipHorizonal:
            return flipHorizontallyCoordinates;
            
        case MetalImageFlipVertically:
            return flipVerticallyCoordinates;
            
        case MetalImageRotateClockwiseAndFlipVertically:
            return rotateClockwiseAndFlipVerticallyCoordinates;
            
        case MetalImageRotateClockwiseAndFlipHorizontally:
            return rotateClockwiseAndFlipHorizontallyCoordinates;
            
        default:
            return noRotationCoordinates;
            break;
    }
}

- (MetalImageCoordinate)texturePositionToSize:(CGSize)targetSize contentMode:(MetalImageContentMode)contentMode {
    CGSize texturePortraitSize = CGSizeZero;
    if (self.orientation == MetalImagePortrait || self.orientation == MetalImagePortraitUpsideDown) {
        texturePortraitSize = CGSizeMake(self.width, self.height);
    }
    else {
        texturePortraitSize = CGSizeMake(self.height, self.width);
    }
    
    float heightScaling, widthScaling = 0.0;
    CGSize aspectSize = [self makeRectWithAspectRatio:texturePortraitSize destSize:targetSize].size;
    MetalImageCoordinate position;
    switch (contentMode) {
        case MetalImageContentModeScaleToFill:
            widthScaling = 1.0;
            heightScaling = 1.0;
            break;
            
        case MetalImageContentModeScaleAspectFit:
            widthScaling = aspectSize.width / targetSize.width;
            heightScaling = aspectSize.height / targetSize.height;
            break;
            
        case MetalImageContentModeScaleAspectFill: {
            widthScaling = targetSize.height / aspectSize.height;
            heightScaling = targetSize.width / aspectSize.width;
            break;
        }
            
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
    
    [[self class] texutreDataProviderProcess:texture process:^(CFDataRef imageData, CGSize imageSize, NSUInteger bytesPerRow) {
        [self.metalTexture replaceRegion:MTLRegionMake2D(0, 0, imageSize.width, imageSize.height)
                             mipmapLevel:0
                               withBytes:CFDataGetBytePtr(imageData)
                             bytesPerRow:4 * imageSize.width];
    }];
}

+ (UIImage *)imageFromMTLTexture:(id<MTLTexture>)texture {
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    MTLPixelFormat pixelFormat = texture.pixelFormat;
    if (pixelFormat == MTLPixelFormatBGRA8Unorm || pixelFormat == MTLPixelFormatBGRA8Unorm_sRGB) {
        bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;//BGRA
    } else if (pixelFormat == MTLPixelFormatRGBA8Unorm || pixelFormat == MTLPixelFormatRGBA8Unorm_sRGB){
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;//ARGB
    }
    
    __block UIImage *image = nil;
    [[self class] texutreDataProviderProcess:texture process:^(CFDataRef imageData, CGSize imageSize, NSUInteger bytesPerRow) {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(imageData);
        
        int bitsPerComponent = 8;
        int bitsPerPixel = 32;
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
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
        
        image = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:UIImageOrientationUp];
        
        CFRelease(provider);
        CFRelease(colorSpaceRef);
        CFRelease(imageRef);
    }];
    
    return image;
}

+ (void)textureCVPixelBufferProcess:(id<MTLTexture>)texture process:(void(^)(CVPixelBufferRef pixelBuffer))process {
    if (!texture) {
        return ;
    }
    
    __block CVPixelBufferRef pixelBuffer = NULL;
    [[self class] texutreDataProviderProcess:texture process:^(CFDataRef imageData, CGSize imageSize, NSUInteger bytesPerRow) {
        CVReturn ret = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, imageSize.width, imageSize.height,
                                                    kCVPixelFormatType_32BGRA,
                                                    (void *)CFDataGetBytePtr(imageData),
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
    }];
}

+ (void)texutreDataProviderProcess:(id<MTLTexture>)texture process:(void(^)(CFDataRef imageData, CGSize imageSize, NSUInteger bytesPerRow))process {
    @autoreleasepool {
        CGSize imageSize = CGSizeMake([texture width], [texture height]);
        NSUInteger bytesPerRow = imageSize.width * 4;
        size_t imageByteCount = imageSize.width * imageSize.height * 4;
        void *imageBytes = malloc(imageByteCount);
        MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
    
        [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
        CFDataRef imageData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, imageBytes, imageByteCount,kCFAllocatorDefault);
        
        if (process) {
            process(imageData, imageSize, bytesPerRow);
        }
        
        CFRelease(imageData);
    }
}
@end
