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

class BoxEnemy : Enemy {
    
    init() {
        super.init(name: "Cube", texture: "Texture2.png", fragmentType: FragmentType.Texture)
        self.topSpeed = float2(10,10)
        changeAcceleration(-BoxEnemyConst.acc)
    }
    
    override func update(dt: Float, currentTime ct : Float) {
        
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
        }
        
        super.update(dt, currentTime: ct)
    }
    
}