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
    static let acc_air      : Float  = 60
    static let deceleration : Float  = 90
    static let deceleration_air : Float  = 90
    static let jump         : Float  = 41
    static let jump_short   : Float  = 18
    static let walljump     : float2 = float2(13, 30)
}

class Player : Model {
    
    
    var onWall : Bool  { get{ return contactState.onWall() }}
    var isWallSliding : Bool { get { return (onWall || isDelayedWallSliding) && velocity.y < 0}}
    var isDelayedWallSliding : Bool { get {
        return currentTime - lastWallTime < 0.3 && velocity.y < 0
    }}
    var lastWallTime : Float = 0
    var lastWallSide : Direction = Direction.None
    var currentTime : Float = 0
    
    var canPickUp = false
    var wantsJump = false
    
    init() {
        super.init(name: "LittleBoy", texture: "Texture.png", fragmentType: FragmentType.TextureLight)
        self.rotateX(-90)
        self.rotateY(-90)
//        self.hitbox?.origin.y -= 0.05
        self.hitbox?.height = Settings.gridSize * 0.9
        self.didUpdateHitbox()
        self.renderingObject?.setOffset(float4(0, Settings.gridSize * 0.6, 0,1))
//        self.moveBy(float3(0,Settings.gridSize * 0.6, 1))
        self.children = [Model]()
        self.mass = 10
        
        self.topSpeed = float2(25, 50)
        self.acc = float2(30,40)
        self.collision_type = CollisionBitmask.Player
    }
    
    override func update(dt: Float, currentTime ct : Float) {
        currentTime = ct
        handleAnimations(dt)
        let gravity_delta = dt * Float(Settings.gravity * mass)
        
        if isWallSliding{
            velocity.y += Float(gravity_delta) * 0.3
            velocity.y = max(velocity.y, -10)
        } else {
            velocity.y += Float(gravity_delta)
        }
        
        if horizontal_state == .Decelerating{
            if abs(velocity.x) >= self.friction {
                velocity.x -= Float(Math.sign(velocity.x)) * self.friction
            } else {
                velocity.x = 0
            }
        } else if !dead {
            //Accelerate or decelerate depending on direction
            if Math.sign(acceleration.x) == Math.sign(velocity.x){
                var air_mult : Float = 1.0
                if !onGround {
                    air_mult = PlayerConst.acc_air / acc.x
                }
                velocity += acceleration * dt * air_mult
            } else {
                var decel = PlayerConst.deceleration
                if !onGround {
                    decel = PlayerConst.deceleration_air
                }
                velocity.x += -Float(Math.sign(velocity.x)) * decel * dt
            }
        }
        
        super.update(dt, currentTime: ct)
    }
    
    func runRight(){
        changeAcceleration(acc.x)
    }
    
    func runLeft(){
        changeAcceleration(-acc.x)
    }
    
    func stop(){
        changeAcceleration(0)
    }
    
    func jumpOffEnemy(){
        if wantsJump {
            jump()
        } else {
            jumpShort()
        }
    }
    
    func jumpStart(){
        wantsJump = true
        if onGround {
            jump()
        } else{
//            if onWall {
//                if contactState.onWallToRight() {
//                    velocity.x = -PlayerConst.walljump.x
//                } else {
//                    velocity.x = PlayerConst.walljump.x
//                }
//                velocity.y = PlayerConst.walljump.y
//            } else
            if isDelayedWallSliding {
                lastWallTime = 0
                lastWallSide = .None
                if direction == .Left{
                    velocity.x = -PlayerConst.walljump.x
                } else {
                    velocity.x = PlayerConst.walljump.x
                }
                velocity.y = PlayerConst.walljump.y
            }
        }
    }
    
    func jump(){
        velocity.y = PlayerConst.jump
    }
    func jumpShort(){
        velocity.y = PlayerConst.jump_short
    }
    
    func jumpEnd(){
        wantsJump = false
        guard !dead else {
            return
        }
        if !contactState.onGround() && velocity.y > PlayerConst.jump_short {
            jumpShort()
        }
    }
    
   
    
    override func updateToNextRect(){
        super.updateToNextRect()
        if isDelayedWallSliding {
            if lastWallSide == .Right {
                setDirection(.Left)
            } else if lastWallSide == .Left {
                setDirection(.Right)
            }
        } else if (!onWall || onGround) {
            if acceleration.x < 0 {
                setDirection(.Left)
            } else if acceleration.x > 0{
                setDirection(.Right)
            }
        }
//        else if isWallSliding {
//            if contactState.onWallToLeft() {
//                setDirection(.Right)
//            } else if contactState.onWallToRight() {
//                setDirection(.Left)
//            }
//        }
    }
    
    override func handleAnimations(dt : Float) {
        
        var anim_dt = dt
        if animation_state == .Running {
            anim_dt = dt * abs(velocity.x)/10
        }
        super.handleAnimations(anim_dt)
        
    }
    
    override func getAnimationState() -> AnimationType {
        if onGround && (horizontal_state == .None || onWall){
            return .Resting
        } else if onGround && isRunning {
            return .Running
        } else if isWallSliding {
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
    
    
    func pickup(m : Model) {
        guard m.parent == nil else {
            return
        }
        if m is PickupObject {
            m.parent = self
            children!.append(m)
            flipChildren(direction)
            print("Did pickup")
        }
    }
    
    func releaseChildren(){
        for c in children!  {
            let p = c as! PickupObject
            p.modelDidPush(self)
            p.parent = nil
        }
        children!.removeAll()
    }

    func flipChildren(dir : Direction){
        for c in children! {
            let x_delta = dir == .Right ? (self.rect.max.x + c.rect.width/2) : (self.rect.x - c.rect.width/2)
            c.moveTo(float3(x_delta, self.rect.mid.y + 0.4, 0))
        }
    }

    override func flipDirection() {
        super.flipDirection()
        flipChildren(direction)
    }
    
    override func setDirection(dir: Direction) {
        if direction != dir {
            flipChildren(dir)
        }
        super.setDirection(dir)
    }
    
    func diedFromEnemy(){
        self.velocity.y = 20
        self.died()
        
    }
    override func died(){
        super.died()
        velocity.x = 0
        for c in children!  {
            c.parent = nil
        }
        children!.removeAll()
        self.collision_bitmask = 0
    }
    
    override func didIntersectWithModel(m: Model, side: Direction, vector : float2) {
        super.didIntersectWithModel(m, side: side, vector: vector)
    }
    
    override func didIntersectWithObject(o : Object, side : Direction){
        
        super.didIntersectWithObject(o, side: side)

        switch(side){
        case .Top:
            if velocity.y <= 0 {
                velocity.y = 0
                contactState.setOnGround()
            }
        case .Right:
            if velocity.x < 0 {
                lastWallSide = .Left
                contactState.setOnLeftWall()
                lastWallTime = currentTime
                velocity.x = 0
            }
        case .Left:
            if velocity.x > 0 {
                lastWallSide = .Right
                contactState.setOnRightWall()
                lastWallTime = currentTime
                velocity.x = 0
            }
        case .Bottom:
            if velocity.y > 0 {
                velocity.y = 0
                contactState.setOnRoof()
            }
        case .None:
            break
        }
    
    }
}