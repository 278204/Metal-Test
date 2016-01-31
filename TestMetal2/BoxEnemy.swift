//
//  BoxEnemy.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-31.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class BoxEnemyConst {
    static let friction     : Float  = 0.96
    static let acc          : Float  = 150
    static let deceleration : Float  = 90
    static let topSpeed     : Float  = 10
}

class BoxEnemy : Model {
    
    init() {
        super.init(name: "Cube", texture: "Texture2.png")
        changeAcceleration(-BoxEnemyConst.acc)
    }
    
    override func update(dt: Float, currentTime ct : Float) {
        super.update(dt, currentTime: ct)
        handleAnimations(dt)
        
        let gravity_delta = dt * Float(Settings.gravity * mass)
        velocity.y += Float(gravity_delta)
        
        if horizontal_state == .Decelerating{
            if abs(velocity.x) >= BoxEnemyConst.friction {
                velocity.x -= BoxEnemyConst.friction * Float(Math.sign(velocity.x))
            } else {
                velocity.x = 0
            }
        } else {
            //Accelerate or decelerate depending on direction
            if Math.sign(acceleration.x) == Math.sign(velocity.x){
                velocity += acceleration * dt
            } else {
                velocity.x += -Float(Math.sign(velocity.x)) * BoxEnemyConst.deceleration * dt
            }
            
            //TopSpeed
            if abs(velocity.x) > BoxEnemyConst.topSpeed {
                velocity.x = Float(Math.sign(velocity.x)) * min(abs(velocity.x), BoxEnemyConst.topSpeed)
            }
        }
        
        try_moveBy(float3(velocity.x * dt, velocity.y * dt, 0))
    }
    
    override func handleIntersectWithObject(o : Object, side : Direction){
        switch(side){
        case .Top:
            velocity.y = 0
            contactState.setOnGround()
        case .Right:
            velocity.x = 0
            changeAcceleration(BoxEnemyConst.acc)
        case .Left:
            velocity.x = 0
            changeAcceleration(-BoxEnemyConst.acc)
        case .Bottom:
            velocity.y = 0
        case .None:
            break
        }
        
    }
}