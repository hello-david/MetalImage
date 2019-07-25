#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MetalImage.h"
#import "MetalImageAudioResource.h"
#import "MetalImageDevice.h"
#import "MetalImageProtocol.h"
#import "MetalImageRenderProcess.h"
#import "MetalImageResource.h"
#import "MetalImageTexture.h"
#import "MetalImageTextureCache.h"
#import "MetalImageTextureResource.h"
#import "NSBundle+MetalImageBundle.h"
#import "MetalImageFilter.h"
#import "MetalImageCamera.h"
#import "MetalImagePicture.h"
#import "MetalImageSource.h"
#import "MetalImageMovieWriter.h"
#import "MetalImageTarget.h"
#import "MetalImageView.h"
#import "MetalImageCropFilter.h"
#import "MetalImageTransformFilter.h"
#import "MetalImageiOSBlurFilter.h"
#import "MetalImageConvolutionFilter.h"
#import "MetalImageGaussianBlurFilter.h"
#import "MetalImageSharpenFilter.h"
#import "MetalImageContrastFilter.h"
#import "MetalImageHueFilter.h"
#import "MetalImageLookUpTableFilter.h"
#import "MetalImageLuminanceFilter.h"
#import "MetalImageSaturationFilter.h"

FOUNDATION_EXPORT double MetalImageVersionNumber;
FOUNDATION_EXPORT const unsigned char MetalImageVersionString[];

