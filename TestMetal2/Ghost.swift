//
//  Ghost.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-01.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class GhostConst {
    static let deceleration : Float  = 90
}

class Ghost : WallBounceEnemy {
    
    init() {
        super.init(name: "Ghost", texture: "Ghost.png", fragmentType: FragmentType.TextureLight)
        self.rotateX(-90)
        self.rotateY(-90)
//        self.hitbox?.origin.y -= 1
        self.hitbox?.height = Settings.gridSize*0.8
        self.hitbox?.width *= 0.8
        self.renderingObject?.setOffset(float4(0,1.3,0,1))
        self.didUpdateHitbox()
        self.topSpeed   = float2(2,40)
        self.acc        = float2(4,4)
        changeAcceleration(-acc.x)
        self.collision_type = CollisionBitmask.Enemy
    }
    
    override func update(dt: Float, currentTime ct : Float) {

        handleAnimations(dt)
        
        let gravity_delta = dt * Float(Settings.gravity * mass)
        velocity.y += Float(gravity_delta)
        
        //Accelerate or decelerate depending on direction
        if Math.sign(acceleration.x) == Math.sign(velocity.x){
            velocity += acceleration * dt
        } else {
            velocity.x += -Float(Math.sign(velocity.x)) * GhostConst.deceleration * dt
        }
        super.update(dt, currentTime: ct)
    }
    
    override func changeAcceleration(a: Float) {
        super.changeAcceleration(a)
        if a < 0 && direction == .Right {
            flipDirection()
        } else if a > 0 && direction == .Left {
            flipDirection()
        }
    }

}