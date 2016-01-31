//
//  GridView.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class GridView: UIScrollView {

    let gridColor = UIColor(white: 0.9, alpha: 1.0)
    override init(frame : CGRect){
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.whiteColor()
    }
    
    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        // Create a gradient
        let colors : [CGFloat] = [74/255, 154/255, 247/255, 1.0, 166/255, 218/255, 254/255, 1.0]
        
        let baseSpace = CGColorSpaceCreateDeviceRGB();
        let gradient = CGGradientCreateWithColorComponents(baseSpace, colors, nil, 2);
        
        CGContextSaveGState(ctx);
        CGContextAddRect(ctx, rect)
        CGContextClip(ctx);
        
        let startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
        let endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        
        CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, CGGradientDrawingOptions.DrawsAfterEndLocation);
        
        //Create grid
        let gridSize = Settings.gridSize * 20

        let nr_grid_x = Int(rect.width / CGFloat(gridSize))
        let nr_grid_y = Int(rect.height / CGFloat(gridSize))
        
        for i in 0..<nr_grid_x{
            CGContextMoveToPoint(ctx,       CGFloat(Float(i) * gridSize), rect.height - 0)
            CGContextAddLineToPoint(ctx,    CGFloat(Float(i) * gridSize), rect.height - (500 * 20))
        }
        for i in 0..<nr_grid_y {
            CGContextMoveToPoint(ctx,       0,  rect.height - CGFloat(Float(i) * gridSize))
            CGContextAddLineToPoint(ctx,    1000 * 20, rect.height - CGFloat(Float(i) * gridSize))
        }
        
        CGContextSetLineWidth(ctx, 1.0)
        CGContextSetStrokeColorWithColor(ctx, gridColor.CGColor)
        
        CGContextStrokePath(ctx)
        

    }
    
}
