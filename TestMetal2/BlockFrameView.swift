//
//  BlockFrameView.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-12.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class BlockFrameView : UIView {
    
    
    override func drawRect(rect: CGRect) {

        let blockSize : CGFloat = 20
        let frameHeight = rect.size.height / blockSize
        let frameWidth = rect.size.width / blockSize
        
        let ctx = UIGraphicsGetCurrentContext()
        
        let cornerOffset : CGFloat = 3
        CGContextMoveToPoint(ctx, blockSize * 2, 0)
        
        CGContextAddRect(ctx, CGRect(x: blockSize*cornerOffset, y: 0, width: (frameWidth - cornerOffset*2) * blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize*cornerOffset, y: (frameHeight - 1) * blockSize, width: (frameWidth - cornerOffset*2) * blockSize, height: blockSize))
        
        CGContextAddRect(ctx, CGRect(x: 0, y: blockSize * cornerOffset, width: blockSize, height: (frameHeight - cornerOffset*2) * blockSize))
        CGContextAddRect(ctx, CGRect(x: (frameWidth-1) * blockSize, y: blockSize * cornerOffset, width: blockSize, height: (frameHeight - cornerOffset*2) * blockSize))
        
        
        CGContextAddRect(ctx, CGRect(x: blockSize * 2, y: blockSize * 1, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 3, y: blockSize * 1, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 1, y: blockSize * 2, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 2, y: blockSize * 2, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 1, y: blockSize * 3, width: blockSize, height: blockSize))
        
        
        CGContextAddRect(ctx, CGRect(x: blockSize * 2, y: blockSize * (frameHeight - 2), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 3, y: blockSize * (frameHeight - 2), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 1, y: blockSize * (frameHeight - 3), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 2, y: blockSize * (frameHeight - 3), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * 1, y: blockSize * (frameHeight - 4), width: blockSize, height: blockSize))
        
        
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 3), y: blockSize * 1, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 4), y: blockSize * 1, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 2), y: blockSize * 2, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 3), y: blockSize * 2, width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 2), y: blockSize * 3, width: blockSize, height: blockSize))
        
        
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 3), y: blockSize * (frameHeight - 2), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 4), y: blockSize * (frameHeight - 2), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 2), y: blockSize * (frameHeight - 3), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 3), y: blockSize * (frameHeight - 3), width: blockSize, height: blockSize))
        CGContextAddRect(ctx, CGRect(x: blockSize * (frameWidth - 2), y: blockSize * (frameHeight - 4), width: blockSize, height: blockSize))
        
        
        CGContextSetFillColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextFillPath(ctx)
    }
}
