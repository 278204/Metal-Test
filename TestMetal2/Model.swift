//
//  Model.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import Metal
import simd
import UIKit

class Model{
    
    let model_key : String
    var transform : float4x4
    var position : float3 = float3(0,0,0)   {didSet{    positionDidSet()    }}
    var hitbox  : Box?                      {didSet{    hitboxDidSet()      }}
    var next_rect : CGRect = CGRectZero
    
    var uniformBuffer : MTLBuffer?
    var velocity : float2 = float2(0,0)
    var dynamic = true
    var onGround = false {didSet {}}
    var mass = 6.0
    
    init(name : String){
        transform = Matrix.Identity()
        model_key = name
    }
    
    func update(dt : Double){
        if dynamic {
            if !onGround {
                let gravity_delta = dt * PhysicsSettings.gravity * mass
                velocity.y += Float(gravity_delta)
            }

            try_moveBy(float3(velocity.x * Float(dt), velocity.y * Float(dt), 0))
        }
    }
    
    func jumpStart(){
        print("jump start")
        onGround = false;
        velocity.y = 14
    }
    
    func jumpEnd(){
        print("jump end")
        
        if !onGround && velocity.y > 5 {
            velocity.y = 5
        }
    }
    
    func moveBy(offset : float3) {
        var pos = position
        pos.x += offset.x
        pos.y += offset.y
        pos.z += offset.z
        position = pos
    }
    
    func try_moveBy(offset : float3) {
        var pos = position
        pos.x += offset.x
        pos.y += offset.y
        pos.z += offset.z

        next_rect.origin.x = CGFloat(pos.x)
        next_rect.origin.y = CGFloat(pos.y)
    }
    
    func updateToNextRect(){
        var pos = position
        pos.x = Float(next_rect.origin.x)
        pos.y = Float(next_rect.origin.y)
        self.position = pos
        
//        print("New position: \(pos)")
    }
    
    func landendOnGround(){
        if onGround == true {
            velocity.y = 0
        }
    }
    
    func positionDidSet(){
        transform[3].x = position.x
        transform[3].y = position.y
        transform[3].z = position.z
        
        hitbox?.origin.x = position.x - hitbox!.width/2
        hitbox?.origin.y = position.y - hitbox!.height/2
        hitbox?.origin.z = position.z - hitbox!.depth/2
        
        next_rect.origin.x = CGFloat(position.x)
        next_rect.origin.y = CGFloat(position.y)
    }
    
    func hitboxDidSet(){
        next_rect.size.height   = CGFloat(hitbox!.height)
        next_rect.size.width    = CGFloat(hitbox!.width)
        next_rect.origin.x      = CGFloat(hitbox!.origin.x)
        next_rect.origin.y      = CGFloat(hitbox!.origin.y)
    }
    
    func handleIntersectWithRect(rect : CGRect){
        let bottomPoint = CGPoint(x: next_rect.origin.x + next_rect.width/2, y: next_rect.origin.y)
        onGround = false
        
        if CGRectContainsPoint(rect, bottomPoint){

            let intersection = CGRectIntersection(rect, next_rect)
            next_rect.origin.y += intersection.height
            onGround = true
            
        } else{
            let topPoint = CGPoint(x: bottomPoint.x, y: next_rect.origin.y + next_rect.height)
            if CGRectContainsPoint(rect, topPoint) {

                let intersection = CGRectIntersection(rect, next_rect)
                next_rect.origin.y -= intersection.height
                velocity.y = 0
            }
        }
    }
}
