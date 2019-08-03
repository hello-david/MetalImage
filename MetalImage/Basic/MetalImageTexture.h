//
//  MetalImageTexture.h
//  MetalImage
//
//  Created by David.Dai on 2018/12/11.
//

#import <Foundation/Foundation.h>
#import <Metal/MTLTexture.h>
#import <Metal/MTLDevice.h>

typedef struct {
    float bottomLeftX;
    float bottomLeftY;
    
    float bottomRightX;
    float bottomRightY;
    
    float topLeftX;
    float topLeftY;
    
    float topRightX;
    float topRightY;
} MetalImageCoordinate;

typedef enum {
    MetalImageNoRotation,            // 不旋转
    MetalImageRotateCounterclockwise,// 顺时针旋转90
    MetalImageRotateClockwise,       // 逆时针旋转90
    MetalImageRotate180,             // 顺时针180
    
    MetalImageFlipHorizonal,         // 水平对称
    MetalImageFlipVertically,        // 垂直对称
    
    MetalImageRotateClockwiseAndFlipVertically,  // 顺时针并垂直对称
    MetalImageRotateClockwiseAndFlipHorizontally,// 顺时针并水平对称
} MetalImageRotationMode;

typedef enum {
    MetalImagePortrait,
    MetalImagePortraitUpsideDown,
    MetalImageLandscapeLeft,
    MetalImageLandscapeRight
} MetalImageOrientation;

typedef enum {
    MetalImageContentModeScaleToFill,    // 拉伸图像，铺满全部渲染空间
    MetalImageContentModeScaleAspectFit, // 缩放图像，保持比例，可能不会填充满整个区域
    MetalImageContentModeScaleAspectFill // 缩放图像，保持比例，会填充整个区域
} MetalImageContentMode;

typedef enum {
    MetalImagContentBackgroundColor,
    MetalImagContentBackgroundFilter,
} MetalImagContentBackground;

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageTexture : NSObject
@property (nonatomic, strong, readonly) id<MTLTexture> metalTexture;
@property (nonatomic, assign, readonly) NSUInteger width;
@property (nonatomic, assign, readonly) NSUInteger height;
@property (nonatomic, assign, readonly) CGSize size;
@property (nonatomic, assign, readonly) MTLPixelFormat pixelFormat;
@property (nonatomic, assign, readonly) BOOL willCache;

@property (nonatomic, assign) MetalImageOrientation orientation;
@property (nonatomic, copy) NSString *cacheKey;

- (instancetype)initWithTexture:(id<MTLTexture>)texutre orientation:(MetalImageOrientation)orientation willCache:(BOOL)willCache;
- (MetalImageCoordinate)textureCoordinatesToOrientation:(MetalImageOrientation)orientation;
- (MetalImageCoordinate)texturePositionToSize:(CGSize)targetSize contentMode:(MetalImageContentMode)contentMode;
- (UIImage *)imageFromTexture;
- (void)replaceTexture:(id<MTLTexture>)texture;

+ (void)textureCVPixelBufferProcess:(id<MTLTexture>)texture process:(void(^)(CVPixelBufferRef pixelBuffer))process;
+ (UIImage *)imageFromMTLTexture:(id<MTLTexture>)texture;
@end

NS_ASSUME_NONNULL_END
