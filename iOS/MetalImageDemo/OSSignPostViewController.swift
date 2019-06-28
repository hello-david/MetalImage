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
        filter.rangeReductionFactor = 0.4
        return filter
    }()
    
    private lazy var saturationFilter: MetalImageSaturationFilter = {
        let filter = MetalImageSaturationFilter.init()
        filter.saturation = 0.6
        return filter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picture.processImage(byFilters: [luminanceFilter, saturationFilter]) { [weak self] (textureResource) in
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
