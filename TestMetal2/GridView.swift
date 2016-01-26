//
//  GridView.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class GridView: UIView {

    override init(frame : CGRect){
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        let gridSize = Settings.gridSize * 20
        for i in 0..<25{
            CGContextMoveToPoint(ctx,       CGFloat(Float(i) * gridSize), rect.height - 0)
            CGContextAddLineToPoint(ctx,    CGFloat(Float(i) * gridSize), rect.height - (500 * 20))
            
            CGContextMoveToPoint(ctx,       0,  rect.height - CGFloat(Float(i) * gridSize))
            CGContextAddLineToPoint(ctx,    1000 * 20, rect.height - CGFloat(Float(i) * gridSize))
        }
        
        CGContextSetLineWidth(ctx, 1.0)
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        
        CGContextStrokePath(ctx)
    }
    
}
