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

class OSSignPostViewController: UIViewController {
    
    @IBOutlet weak var frameView: MetalImageView!
    
    private lazy var picture: MetalImagePicture = {
        return MetalImagePicture.init(image: UIImage.init(named: "1.jpg")!)
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
        
        
        picture.processImage(byFilters: [saturationFilter, gaussianFilter, luminanceFilter]) { [weak self] (textureResource) in
            guard textureResource != nil else {
                return
            }
            
            self?.frameView.receive(textureResource!, with: CMTime.invalid)
        }
    }
}

extension OSLog {
    @available(iOS 10.0, *)
    static let filter = OSLog(subsystem: "com.metalImage", category: "Test")
}
