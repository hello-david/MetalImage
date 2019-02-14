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
    kMetalImageNoRotation,            // 不旋转
    kMetalImageRotateCounterclockwise,// 顺时针旋转90
    kMetalImageRotateClockwise,       // 逆时针旋转90
    kMetalImageRotate180,             // 顺时针180
    
    kMetalImageFlipHorizonal,         // 水平对称
    kMetalImageFlipVertically,        // 垂直对称
    
    kMetalImageRotateClockwiseAndFlipVertically,  // 顺时针并垂直对称
    kMetalImageRotateClockwiseAndFlipHorizontally,// 顺时针并水平对称
} MetalImageRotationMode;

typedef enum {
    kMetalImagePortrait,
    kMetalImagePortraitUpsideDown,
    kMetalImageLandscapeLeft,
    kMetalImageLandscapeRight
} MetalImageOrientation;

typedef enum {
    kMetalImageContentModeScaleToFill,    // 显示全部图像，铺满全部渲染空间
    kMetalImageContentModeScaleAspectFit, // 调整图像比例，显示全部图像
    kMetalImageContentModeScaleAspectFill // 调整图像比例，铺满全部渲染空间
} MetalImageContentMode;

typedef enum {
    kMetalImagContentBackgroundColor,
    kMetalImagContentBackgroundFilter,
} MetalImagContentBackground;

NS_ASSUME_NONNULL_BEGIN

@interface MetalImageTexture : NSObject
@property (nonatomic, strong) id<MTLTexture> metalTexture;
@property (nonatomic, assign) NSUInteger width;
@property (nonatomic, assign) NSUInteger height;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) MTLPixelFormat pixelFormat;
@property (nonatomic, assign) MetalImageOrientation orientation;
@property (nonatomic, copy) NSString *cacheKey;
@property (nonatomic, readonly) BOOL willCache;

- (instancetype)initWithTexture:(id<MTLTexture>)texutre orientation:(MetalImageOrientation)orientation willCache:(BOOL)willCache;
- (MetalImageCoordinate)textureCoordinatesToOrientation:(MetalImageOrientation)orientation;
- (MetalImageCoordinate)texturePositionToSize:(CGSize)targetSize contentMode:(MetalImageContentMode)contentMode;
- (UIImage *)imageFromTexture;
- (void)replaceTexture:(id<MTLTexture>)texture;

+ (void)textureCVPixelBufferProcess:(id<MTLTexture>)texture process:(void(^)(CVPixelBufferRef pixelBuffer))process;
+ (UIImage *)imageFromMTLTexture:(id<MTLTexture>)texture;
+ (id<MTLTexture>)textureFromImage:(UIImage *)image device:(id<MTLDevice>)device;
@end

NS_ASSUME_NONNULL_END
