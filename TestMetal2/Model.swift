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



enum VelocityState {
    case None
    case Accelerating
    case Decelerating
}

enum ModelState {
    case Unknown
    case OnGround
    case Jumping
    case Falling
    case WallSliding
}

enum AnimationType {
    case Unknown
    case Resting
    case Running
    case Jumping
    case WallGliding
    
    static func stringToState(s : String)->AnimationType{
        switch(s){
        case "resting":
            return .Resting
        case "wallSliding":
            return .WallGliding
        case "run":
            return .Running
        case "jump":
            return .Jumping
        default:
            return .Unknown
        }
    }
}

enum Direction {
    case Right
    case Left
    case Top
    case Bottom
}

protocol ModelDelegate{
    func modelDidChangePosition(model : Model)
}

class ModelConst {
    static let friction     : Float  = 0.96
    static let acc          : Float  = 30
    static let deceleration : Float  = 90
    static let topSpeed     : Float  = 30
    static let jump         : Float  = 50
    static let jump_short   : Float  = 20
    static let walljump     : float2 = float2(20, 40)
}

class Model : Object{
    
    var delegate : ModelDelegate?
    var current_rect = CGRectZero
    var velocity : float2 = float2(0,0)
    var acceleration = float2(0,0)
    var mass = 15.0
    var direction = Direction.Right
    var state = ModelState.Unknown
    var horizontal_state = VelocityState.None
    var animation_state : AnimationType { get { return getAnimationState() }}
    var onWall      : Bool  { get{ return state == .WallSliding                 }}
    var onGround    : Bool  { get{ return state == .OnGround                    }}
    var isRunning   : Bool  { get{ return horizontal_state == .Accelerating     }}
    
    
    override init(name : String, renderingObject ro : RenderingObject?){
        super.init(name: name, renderingObject: ro)
        dynamic = true
    }
    
    func update(dt : Float){
        if dynamic {
            handleAnimations(dt)
            
            if !onGround {
                let wall_fric = onWall && velocity.y < 0 ? 0.1 : 1.0
                let gravity_delta = dt * Float(Settings.gravity * mass * wall_fric)
                velocity.y += Float(gravity_delta)
            }
            
            if !isRunning{
                if abs(velocity.x) >= ModelConst.friction {
                    velocity.x -= ModelConst.friction * Float(Math.sign(velocity.x))
                } else {
                    velocity.x = 0
                }
            } else {
            
                //Accelerate or decelerate depending on direction
                if Math.sign(acceleration.x) == Math.sign(velocity.x) {
                    velocity += acceleration * dt
                } else {
                    velocity.x += -Float(Math.sign(velocity.x)) * ModelConst.deceleration * dt
                }
                
                //TopSpeed
                if abs(velocity.x) > ModelConst.topSpeed {
                    if velocity.x < 0 {
                        velocity.x = -ModelConst.topSpeed
                    } else{
                        velocity.x = ModelConst.topSpeed
                    }
                }
            }
            
            try_moveBy(float3(velocity.x * dt, velocity.y * dt, 0))
            
        }
    }
    
    func try_moveBy(offset : float3) {
        self.rect.origin.x += CGFloat(offset.x)
        self.rect.origin.y += CGFloat(offset.y)
        state = .Unknown
    }
    
    func updateToNextRect(){
        //        var pos = float3(0,0,0)
        let offset = self.rect.origin - self.current_rect.origin
        //        pos.x = Float(self.rect.origin.x + self.rect.width/2)
        //        pos.y = Float(self.rect.origin.y + self.rect.height/2)
        //
        //        super.moveTo(pos)
        
        self.rect = self.current_rect
        
        moveBy(float3(Float(offset.x), Float(offset.y), 0))
        
        if state == .Unknown {
            if velocity.y > 0 {
                state = .Jumping
            } else if velocity.y < 0{
                state = .Falling
            } else {
                print("WARNING, still unknown state")
            }
        } else if state == .OnGround {
            if velocity.x == 0 {
                horizontal_state = .None
            }
        }
        
        if direction == .Right && acceleration.x < 0 && !onWall{
            flipDirection()
        } else if direction == .Left && acceleration.x > 0 && !onWall{
            flipDirection()
        }
    }
    
    
    func handleAnimations(dt : Float) {
        var anim_dt = dt

        renderingObject?.skeleton?.changeAnimation(animation_state)
        if animation_state == .Running {
            renderingObject?.skeleton?.animationHandler.loop = true
            anim_dt = dt * abs(velocity.x)/10
        } else if state == .Jumping{
            renderingObject?.skeleton?.animationHandler.loop = false
        }
        
        renderingObject?.update(anim_dt)
        
    }
    
    func getAnimationState() -> AnimationType {
        if onGround && horizontal_state == .None{
            return .Resting
        } else if onGround && horizontal_state != .None {
            return .Running
        } else if state == .WallSliding && !onGround{
            return .WallGliding
        } else if !onGround {
            return .Jumping
        }
        return .Unknown
    }
    
    func runRight(){
        
        horizontal_state = .Accelerating
        acceleration.x = ModelConst.acc
    }
    func runLeft(){
        
        horizontal_state = .Accelerating
        acceleration.x = -ModelConst.acc
    }
    func stop(){
        acceleration.x = 0
        horizontal_state = .Decelerating
    }
    
    func jumpStart(){
        
        if onGround{
            velocity.y = ModelConst.jump
        } else if onWall {
            velocity.x = ModelConst.walljump.x
            velocity.y = ModelConst.walljump.y
        }
        state = .Jumping
    }
    
    func jumpEnd(){
        if state == .Jumping && velocity.y > ModelConst.jump_short {
            velocity.y = ModelConst.jump_short
        }
    }
    
    func flipDirection(){
        self.renderingObject?.rotateYInPlace(180)
        if direction == .Left {
            direction = .Right
        } else {
            direction = .Left
        }
    }

    override func moveTo(pos : float3){
        super.moveTo(pos)
        current_rect = self.rect
    }
    
    
    override func moveBy(offset : float3) {
        super.moveBy(offset)
        current_rect = self.rect
    }
    



    
    override func didUpdateHitbox(){
        super.didUpdateHitbox()
        current_rect = self.rect
    }

    
    override func positionDidSet(){
        self.delegate?.modelDidChangePosition(self)
    }
    
    func handleIntersectWithRect(o : Object){
        
        let this_aabb = AABB(rect: self.rect)
        let other_aabb = AABB(rect: o.rect)
        
        let md = other_aabb.minkowskiDifference(this_aabb)
        
        if md.origin.x <= 0 && md.get_max().x >= 0 &&
            md.origin.y <= 0 && md.get_max().y >= 0 {
                
                let md_ret = md.closestPointOnBoundsToOrigin(o.collision_bit)
                var penetration_vector = md_ret.0
                
                
                switch(md_ret.1){
                case .Top:
                    velocity.y = 0
                    state = .OnGround
                case .Right:
                    if state != .OnGround {
                        state = .WallSliding
                    }
//                    velocity.x *= 0
//                    penetration_vector.x *= 0.4
                case .Left:
                    if state != .OnGround {
                        state = .WallSliding
                    }
//                    velocity.x *= 0
//                    penetration_vector.x *= 0.4
                default:
                    break
                }
                
                self.rect.origin = self.rect.origin + CGPoint(x: CGFloat(penetration_vector.x), y: CGFloat(penetration_vector.y))
        }
        return

    }
    

}
