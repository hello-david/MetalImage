#
#  Be sure to run `pod spec lint MetalImage.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "MetalImage"
  s.version      = "0.0.1"
  s.summary      = "A short description of MetalImage."
  s.description  = <<-DESC
    MetalImage 为 iOS 平台上一个简单的Metal滤镜处理框架
                   DESC

  s.homepage     = "https://github.com/hello-david/MetalImage.git"
  s.license      = {
    :type => 'Copyright',
    :text => <<-LICENSE
      © 2008-2018 David.Dai. All rights reserved.
    LICENSE
  }

  s.author       = { "david.dai" => "hello.david.me@gmail.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/hello-david/MetalImage.git", :tag => "#{s.version}" }

  s.public_header_files = 'MetalImage/MetalImage.h'
  s.default_subspec = 'Core'
  
  # Core
  s.subspec 'Core' do |core|
      core.subspec 'Basic' do |basic|
          basic.public_header_files = 'MetalImage/Basic/**/*.{h}'
          basic.source_files = 'MetalImage/Basic/**/*.{h,m,cpp,mm}'
      end
      
      core.subspec 'Source' do |source|
          source.public_header_files = 'MetalImage/Source/**/*.{h}'
          source.source_files = 'MetalImage/Source/**/*.{h,m,cpp,mm}'
      end
      
      core.subspec 'Filter' do |filter|
          filter.public_header_files = 'MetalImage/Filter/**/*.{h}'
          filter.source_files = 'MetalImage/Filter/**/*.{h,m,cpp,mm}'
      end
      
      core.subspec 'Target' do |target|
          target.public_header_files = 'MetalImage/Target/**/*.{h}'
          target.source_files = 'MetalImage/Target/**/*.{h,m,cpp,mm}'
      end
      
      core.subspec 'Category' do |category|
          category.public_header_files = 'MetalImage/Category/**/*.{h}'
          category.source_files = 'MetalImage/Category/**/*.{h,m,cpp,mm}'
      end
      
      core.source_files = 'MetalImage/MetalImage.h'
      core.resource_bundles = {
          'MetalLibrary' => [
          'MetalImage/Library/*.metal',
          'MetalImage/Resource/*'
          ]
      }
      
      core.frameworks = "Metal", "MetalKit", "CoreVideo", "AVFoundation"
  end
  
  # 滤镜拓展
  s.subspec 'ExtensionFilter' do |extensionFilter|
      extensionFilter.public_header_files = 'MetalImage/ExtensionFilter/**/*.{h}'
      extensionFilter.source_files = 'MetalImage/ExtensionFilter/**/*.{h,m,cpp,mm}'
      extensionFilter.dependency 'MetalImage/Core'
  end
  
  s.requires_arc = true
end
