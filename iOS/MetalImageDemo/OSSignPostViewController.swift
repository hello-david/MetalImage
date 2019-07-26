//
//  OSSignPostViewController.swift
//  MetalImageDemo
//
//  Created by David.Dai on 2019/6/28.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import os.signpost
import MetalImage

@available(iOS 12.0, *)
class OSSignPostViewController: UIViewController {
    
    @IBOutlet weak var frameView: MetalImageView!
    
    private lazy var picture: MetalImagePicture = {
        return MetalImagePicture.init(image: UIImage.init(named: "1.jpg")!)
    }()
    
    private lazy var camera: MetalImageCamera = {
       return MetalImageCamera.init(sessionPreset: AVCaptureSession.Preset.hd1920x1080, cameraPosition: AVCaptureDevice.Position.back)
    }()
    
    private lazy var luminanceFilter: MetalImageLuminanceFilter = {
        let filter = MetalImageLuminanceFilter.init()
        filter.rangeReductionFactor = -0.5
        return filter
    }()
    
    private lazy var saturationFilter: MetalImageSaturationFilter = {
        let filter = MetalImageSaturationFilter.init()
        filter.saturation = 0.3
        return filter
    }()
    
    private lazy var gaussianFilter: MetalImageGaussianBlurFilter = {
        let filter = MetalImageGaussianBlurFilter.init()
        filter.blurRadiusInPixels = 8.0
        filter.texelSpacingMultiplier = 1.0
        return filter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera.add(saturationFilter)
        saturationFilter.add(gaussianFilter)
        gaussianFilter.add(luminanceFilter)
        luminanceFilter.add(frameView)
        
        let filterChainProcessBlock: MetalImageFilterBlock = {(beforeFilter, textureReousrece, filter) in
            struct StaticVar { static var postId = OSSignpostID(log: .metalImage) }
            if beforeFilter {
                StaticVar.postId = OSSignpostID(log: .metalImage)
                os_signpost(.begin, log: .metalImage, name: "Filter", signpostID: StaticVar.postId, "b_%s", NSStringFromClass(filter.classForCoder))
                return;
            }
            os_signpost(.end, log: .metalImage, name: "Filter", signpostID: StaticVar.postId, "e_%s", NSStringFromClass(filter.classForCoder))
        }
        
        saturationFilter.filterChainProcessHook = filterChainProcessBlock
        gaussianFilter.filterChainProcessHook = filterChainProcessBlock
        luminanceFilter.filterChainProcessHook = filterChainProcessBlock
        camera.startCapture()
    }

    private func processImage() {
        luminanceFilter.rangeReductionFactor = Float.random(in: -1.0..<(-0.3))
        saturationFilter.saturation = Float.random(in: 0.0..<2.0)
        
        os_signpost(.begin, log: .metalImage, name: "Process")
        picture.processImage(byFilters: [saturationFilter, gaussianFilter, luminanceFilter]) { [weak self] (textureResource) in
            guard textureResource != nil else {
                return
            }
            os_signpost(.end, log: .metalImage, name: "Process")
            self?.frameView.receive(textureResource!, with: CMTime.invalid)
        }
    }
}

extension OSLog {
    @available(iOS 10.0, *)
    static let metalImage = OSLog(subsystem: "com.metalImage", category: "Test")
}
