//
//  Player.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-27.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class PlayerConst {
    static let friction     : Float  = 0.96
    static let acc          : Float  = 40
    static let deceleration : Float  = 90
    static let topSpeed     : float2 = float2(25, 50)
    static let jump         : Float  = 50
    static let jump_short   : Float  = 20
    static let walljump     : float2 = float2(20, 40)
}

class Player : Model {
    
    var onWall : Bool  { get{ return contactState.onWall() }}
    var isWallSliding : Bool { get { return onWall && velocity.y < 0 }}
    var lastWallTime : Float = 0
    var currentTime : Float = 0
    init() {

        super.init(name: "LittleBoy", texture: "Texture.png")
        self.rotateX(-90)
        self.rotateY(-90)
        self.hitbox?.origin.y -= 0.05
        self.hitbox?.height = Settings.gridSize * 0.9
        self.didUpdateHitbox()
    }
    
    override func update(dt: Float, currentTime ct : Float) {
        super.update(dt, currentTime: ct)
        currentTime = ct
        handleAnimations(dt)
        
        let gravity_delta = dt * Float(Settings.gravity * mass)
        if isWallSliding{
            velocity.y += Float(gravity_delta) * 0.1
            velocity.y = max(velocity.y, -10)
        } else {
            velocity.y += Float(gravity_delta)
        }
        
        if horizontal_state == .Decelerating{
            if abs(velocity.x) >= PlayerConst.friction {
                velocity.x -= PlayerConst.friction * Float(Math.sign(velocity.x))
            } else {
                velocity.x = 0
            }
        } else {
            //Accelerate or decelerate depending on direction
            if Math.sign(acceleration.x) == Math.sign(velocity.x){
                velocity += acceleration * dt
            } else {
                velocity.x += -Float(Math.sign(velocity.x)) * PlayerConst.deceleration * dt
            }
            
            //TopSpeed
            if abs(velocity.x) > PlayerConst.topSpeed.x {
                velocity.x = Float(Math.sign(velocity.x)) * min(abs(velocity.x), PlayerConst.topSpeed.x)
            }
            if abs(velocity.y) > PlayerConst.topSpeed.y {
                velocity.y = Float(Math.sign(velocity.y)) * min(abs(velocity.y), PlayerConst.topSpeed.y)
            }
        }
        
        try_moveBy(float3(velocity.x * dt, velocity.y * dt, 0))
    }
    
    func runRight(){
        changeAcceleration(PlayerConst.acc)
    }
    
    func runLeft(){
        changeAcceleration(-PlayerConst.acc)
    }
    
    func stop(){
        changeAcceleration(0)
    }
    
    func jumpStart(){
        
        if onGround {
            velocity.y = PlayerConst.jump
        } else{
            if onWall {
                if contactState.onWallToRight() {
                    velocity.x = -PlayerConst.walljump.x
                } else {
                    velocity.x = PlayerConst.walljump.x
                }
                velocity.y = PlayerConst.walljump.y
            } else if currentTime - lastWallTime < 0.1 {
                if acceleration.x < 0 {
                    velocity.x = -PlayerConst.walljump.x
                } else {
                    velocity.x = PlayerConst.walljump.x
                }
                velocity.y = PlayerConst.walljump.y
            }
        }
    }
    
    func jumpEnd(){
        if !contactState.onGround() && velocity.y > PlayerConst.jump_short {
            velocity.y = PlayerConst.jump_short
        }
    }
    
   
    
    override func updateToNextRect(){
        super.updateToNextRect()
        if acceleration.x < 0 && (!onWall || onGround) {
            setDirection(.Left)
        } else if acceleration.x > 0 && (!onWall || onGround) {
            setDirection(.Right)
        } else if isWallSliding {
            if contactState.onWallToLeft() {
                setDirection(.Right)
            } else if contactState.onWallToRight() {
                setDirection(.Left)
            }
        }
    }
    
    override func getAnimationState() -> AnimationType {
        if onGround && (horizontal_state == .None || onWall){
            return .Resting
        } else if onGround && isRunning {
            return .Running
        } else if isWallSliding{
            return .WallGliding
        } else if !onGround {
            if velocity.y > 0 {
                return .Jumping
            } else {
                return .Falling
            }
        }
        return .Unknown
    }
    
    override func died(){
        super.died()
    }
    
    override func handleIntersectWithObject(o : Object, side : Direction){
        let isEnemy = o is Model

        switch(side){
        case .Top:
            velocity.y = 0
            contactState.setOnGround()
        case .Right:
            contactState.setOnLeftWall()
            lastWallTime = currentTime
            velocity.x = -1
        case .Left:
            contactState.setOnRightWall()
            lastWallTime = currentTime
            velocity.x = 1
        case .Bottom:
            velocity.y = 0
            contactState.setOnRoof()
        case .None:
            break
        }
        
        if isEnemy{
            let m = o as! Model
            if side == .Top {
                print("Killed enemy")
                self.rect.origin.y = m.rect.get_max().y
                self.velocity.y = 20
                m.died()
            } else {
                print("Killed by enemy")
                self.died()
            }
        }
        
        
    }
}