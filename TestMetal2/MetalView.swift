//
//  MetalView.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit
import Metal
import QuartzCore

class MetalView : UIView {
    var metalLayer  : CAMetalLayer?
    override var frame : CGRect {
        didSet{
            let scale = UIScreen.mainScreen().scale
            metalLayer?.drawableSize = CGSize(width: self.bounds.width * scale, height: self.bounds.height * scale)
        }
    }
    override class func layerClass() -> AnyClass {
        return CAMetalLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print("Init metal view")
        metalLayer = self.layer as! CAMetalLayer
        
    }
    
    
}
