//
//  MovingPlatform.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-31.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class MovingPlatformConst {
    static let acceleration : Float = 10
}
class MovingPlatform : TopObject {
    
    var firstMoveBy = true
    
    var points = [float2]()
    var currentIndex = 0
    var nextIndex = 1
    var velocity : float2 = float2(0,0)
    
    init(){
        points.append(float2(0,0))
        points.append(float2(20,0))
        points.append(float2(20, 10))
        points.append(float2(0, 10))
        
        super.init(name: "MovingPlatform", texture: "MovingPlatform", fragmentType: FragmentType.Texture)

        self.rotateX(-90)
        can_rest = false
        dynamic = true
        children = [Model]()
        
    }
    
    override func modelDidIntersect(model: Model, side: Direction, penetration_vector: float2) -> Bool{

        let velocity_check = self.velocity.y > 0 ? model.velocity.y <= 0 : model.velocity.y < 0
        
        if model.current_rect.origin.y >= self.current_rect.max.y && velocity_check && (self.collision_side_bit & 0b1000 == 0) {
            
            model.rect.origin += penetration_vector
            return true
        }
        return false
    }
    
    override func updateToNextRect() {
        self.velocity = self.rect.origin - self.current_rect.origin
        super.updateToNextRect()
        for c in children! {
            c.parent = nil
        }
        self.children!.removeAll()
    }
    
    override func moveBy(offset: float3) {
        super.moveBy(offset)
        if firstMoveBy {
            for i in 0..<points.count {
                points[i] += offset.xy
            }
            firstMoveBy = false
        }
    }
    
    
    override func update(dt: Float, currentTime: Float) {
        guard points.count > 0 else {
            return
        }
        
        var endPoint = points[nextIndex]
        
        let end_dist = (endPoint - self.rect.mid).length()

        if end_dist < 1 {
            if nextIndex >= points.count - 1 {
                currentIndex = nextIndex
                nextIndex = 0
            } else {
                currentIndex = nextIndex
                nextIndex += 1
            }
            endPoint = points[nextIndex]
        }
        
        let startPoint = points[currentIndex]

        
        let delta = endPoint - startPoint
        
        let x_sign = delta.x / delta.length()//Float(Math.signWithZero(delta.x))
        let y_sign = delta.y / delta.length()//Float(Math.signWithZero(delta.y))
        
        try_moveBy(float3(x_sign * MovingPlatformConst.acceleration * dt, y_sign * MovingPlatformConst.acceleration * dt, 0))
        
    }
}