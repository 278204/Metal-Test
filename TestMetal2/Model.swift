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

class ModelContactState {
    var bitmask = UInt8(0)
    
    func setOnLeftWall(){
        bitmask |= 0b0001
    }
    func setOnRightWall(){
        bitmask |= 0b0100
    }
    func setOnGround(){
        bitmask |= 0b0010
    }
    func setOnRoof(){
        bitmask |= 0b1000
    }
    
    func onGround() -> Bool{
        return check_bit(1)
    }
    func onWall() -> Bool {
        return onWallToLeft() || onWallToRight()
    }
    func onWallToRight() -> Bool {
        return check_bit(2)
    }
    func onWallToLeft() -> Bool {
        return check_bit(0)
    }
    func onRoof() -> Bool {
        return check_bit(3)
    }
    
    func check_bit(pos : UInt8) -> Bool{
        return bitmask & (1<<pos) != 0
    }
    func reset(){
        bitmask = 0
    }
}

enum AnimationType {
    case Unknown
    case Resting
    case Running
    case Jumping
    case WallGliding
    case Falling
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
        case "fall":
            return .Falling
        default:
            return .Unknown
        }
    }
}

enum Direction {
    case None
    case Right
    case Left
    case Top
    case Bottom
    
    mutating func opposite(){
        switch(self){
        case .Right:
            self = .Left
        case .Left:
            self = .Right
        case .Top:
            self = .Bottom
        case .Bottom:
            self = .Top
        default:
            break
        }
    }
}

protocol ModelDelegate{
    func modelDidChangePosition(model : Model)
    func modelDidDie(model : Model)
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
    var current_rect = AABB(rect: CGRectZero) {didSet{
            assertionFailure()
        }}
    var velocity : float2 = float2(0,0)
    var acceleration = float2(0,0)
    var mass = 15.0
    var direction = Direction.Right
    var contactState = ModelContactState()
    var horizontal_state = VelocityState.None
    var animation_state : AnimationType { get { return getAnimationState() }}
    
    var onGround    : Bool  { get{ return contactState.onGround() }}
    var isRunning   : Bool  { get{ return horizontal_state == .Accelerating  || horizontal_state == .Decelerating   }}
    
    
    override init(name : String, texture : String){
        super.init(name: name, texture: texture)
        dynamic = true
    }
    
    func update(dt : Float, currentTime : Float){
        if self.position.y < -1 {
            self.died()
        }
    }
    
    func try_moveBy(offset : float3) {
        self.rect.origin += offset.xy
        contactState.reset()
    }
    
    func updateToNextRect(){
        let offset = self.rect.origin - self.current_rect.origin
        self.rect.origin = self.current_rect.origin
        moveBy(offset.xyz)
        
        if onGround {
            if velocity.x == 0 && horizontal_state == .Decelerating{
                horizontal_state = .None
            }
        }
    }
    
    func changeAcceleration(a : Float){
        acceleration.x = a
        if a == 0 {
            horizontal_state = .Decelerating
        } else {
            horizontal_state = .Accelerating
        }
    }
    
    func handleAnimations(dt : Float) {
        var anim_dt = dt
        renderingObject?.skeleton?.changeAnimation(animation_state)
        
        if animation_state == .Running {
            renderingObject?.skeleton?.animationHandler.loop = true
            anim_dt = dt * abs(velocity.x)/10
        }
    
        renderingObject?.update(anim_dt)
    }
    
    func getAnimationState() -> AnimationType {
        if onGround && horizontal_state == .None{
            return .Resting
        } else if onGround && isRunning {
            return .Running
        } else if !onGround {
            if velocity.y > 0 {
                return .Jumping
            } else {
                return .Falling
            }
        }
        return .Unknown
    }
    
    
    func setDirection(dir : Direction){
        if dir != direction {
            self.renderingObject?.rotateYInPlace(180)
        }
        direction = dir
    }
    func flipDirection(){
        print("Flip Direction")
        self.renderingObject?.rotateYInPlace(180)
        if direction == .Left {
            direction = .Right
        } else {
            direction = .Left
        }
    }

    override func moveTo(pos : float3){
        super.moveTo(pos)
        self.current_rect.origin = self.rect.origin
    }

    override func moveBy(offset : float3) {
        super.moveBy(offset)
        self.current_rect.origin = self.rect.origin
    }
    
    override func didUpdateHitbox(){
        super.didUpdateHitbox()
        self.current_rect.origin = self.rect.origin
    }
    
    override func positionDidSet(){
        self.delegate?.modelDidChangePosition(self)
    }
    
    func died(){
        self.delegate?.modelDidDie(self)
    }
    
    func handleIntersectWithObject(o : Object, side : Direction){
        switch(side){
        case .Top:
            velocity.y = 0
            contactState.setOnGround()
        case .Right:
            velocity.x = 0
        case .Left:
            velocity.x = 0
        case .Bottom:
            velocity.y = 0
        case .None:
            break
        }
        
    }

    func checkIntersectWithRect(o : Object, dt : Float){
        var md = o.rect.minkowskiDifference(self.rect)
        var handled = false
        if md.isAtOrigo() {
            var md_ret = md.closestPointOnBoundsToOrigin()
            checkCollision(&md_ret, bits: o.collision_bit)
            if md_ret.side != .None {
                handled = true
                handleIntersectWithObject(o, side: md_ret.side)
                if !(o is Model) {
                    self.rect.origin = self.rect.origin + md_ret.penetration_vector
                }
            }
        }
        
        if !handled {
            md = o.rect.minkowskiDifference(self.current_rect)
            var relativeMotion = self.velocity * dt
            if o is Model {
                let m = o as! Model
                relativeMotion = (self.velocity - m.velocity) * dt
            }
            
            var md_ret = md.getRayIntersectionFraction(float2(0,0), directionA: relativeMotion)
            
            //WARNING, cant check for epsilon?
            if md_ret.h < Float.infinity && md_ret.h > 0.000001{
                
                checkCollision(&md_ret, bits: o.collision_bit)
//                collisionsAgaintsVelocity(&md_ret)
                
                if md_ret.side != .None {
                    let h = md_ret.h
                    if md_ret.side == .Left || md_ret.side == .Right {
                        self.rect.origin.x = self.current_rect.origin.x + (self.velocity.x * dt * h)
                    } else {
                        self.rect.origin.y = self.current_rect.origin.y + (self.velocity.y * dt * h)
                    }
                    
                    if o is Model {
                        let m = o as! Model
                        m.rect.origin = m.current_rect.origin + (m.velocity * dt * h)
                    }
                    handleIntersectWithObject(o, side: md_ret.side)
                }
            }
        }
    }
//    func collisionsAgaintsVelocity(inout md_ret : (Float, Direction)){
//        var reset = false
//        switch(md_ret.1){
//        case .Top:
//            if velocity.y > 0 {
//                reset = true
//            }
//        case .Right:
//            if velocity.x > 0 {
//                reset = true
//            }
//        case .Left:
//            if velocity.x < 0 {
//                reset = true
//            }
//        case .Bottom:
//            if velocity.y < 0 {
//                reset = true
//            }
//        case .None:
//            md_ret.0 = Float.infinity
//        }
//        if reset {
//            md_ret.0 = 0
//        }
//    }
}
