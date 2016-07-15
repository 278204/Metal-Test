//
//  WallBounceEnemy.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-02.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


class WallBounceEnemy : Enemy {
    
    override func didIntersectWithObject(o : Object, side : Direction){

        super.didIntersectWithObject(o, side: side)
        
        switch(side){
        case .Top:
            velocity.y = 0
            contactState.setOnGround()
        case .Right:
            velocity.x = 0
            changeAcceleration(acc.x)
        case .Left:
            velocity.x = 0
            changeAcceleration(-acc.x)
        case .Bottom:
            velocity.y = 0
        case .None:
            break
        }
    }
}