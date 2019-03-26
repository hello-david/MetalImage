#
#  Be sure to run `pod spec lint MetalImage.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "MetalImage"
  s.version      = "0.0.1"
  s.summary      = "A short description of MetalImage."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
    MTGPUMetal 为 iOS 平台上一个简单的Metal滤镜处理框架
                   DESC

  s.homepage     = "https://github.com/hello-david/MetalImage.git"

  s.license      = {
    :type => 'Copyright',
    :text => <<-LICENSE
      © 2008-2018 David.Dai. All rights reserved.
    LICENSE
  }

  s.author       = { "David" => "hello.david.me@gmail.com" }

  s.platform     = :ios, "9.0"

  s.source       = { :git => "", :tag => "#{s.version}" }

  s.source_files = 'MetalImage/MetalImage.h'
  
  # ―――--------- MetalImage Core ―――---------
  s.subspec 'Core' do |sp|
      sp.subspec 'Basic' do |spp|
          spp.public_header_files = 'MetalImage/Basic/**/*.{h}'
          spp.source_files = 'MetalImage/Basic/**/*.{h,m,cpp,mm}'
      end
      
      sp.subspec 'Source' do |spp|
          spp.public_header_files = 'MetalImage/Source/**/*.{h}'
          spp.source_files = 'MetalImage/Source/**/*.{h,m,cpp,mm}'
      end
      
      sp.subspec 'Filter' do |spp|
          spp.public_header_files = 'MetalImage/Filter/**/*.{h}'
          spp.source_files = 'MetalImage/Filter/**/*.{h,m,cpp,mm}'
      end
      
      sp.subspec 'Target' do |spp|
          spp.public_header_files = 'MetalImage/Target/**/*.{h}'
          spp.source_files = 'MetalImage/Target/**/*.{h,m,cpp,mm}'
      end
      
      sp.source_files = 'MetalImage/MetalImage.h'
      
      sp.resource_bundles = {
          'MetalImageBundle' => ['MetalImage/Library/*.metal']
      }
      
      sp.frameworks = "Metal", "MetalKit", "CoreVideo", "AVFoundation"
  end
  
  # ―――--------- 滤镜拓展 ―――---------
  s.subspec 'ExtensionFilter' do |sp|
      sp.public_header_files = 'MetalImage/ExtensionFilter/**/*.{h}'
      sp.source_files = 'MetalImage/ExtensionFilter/**/*.{h,m,cpp,mm}'
      sp.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'ExtensionFilter_Pod_Enable=1'}
  end
end
