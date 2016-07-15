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

protocol ModelDelegate{
    func modelDidChangePosition(model : Model)
    func modelWillDie(model : Model)
}

class Model : Object{
    
    var parent              : Object?
    var delegate            : ModelDelegate?
    var direction           = Direction.Right
    var contactState        = ModelContactState()
    var horizontal_state    = VelocityState.None
    
    var topSpeed    : float2
    var acc         : float2
    var friction : Float = 0.96
    var velocity : float2 = float2(0,0)
    var acceleration = float2(0,0)
    var mass = 15.0
    var dead = false
    
    var onGround    : Bool  { get{ return contactState.onGround() }}
    var isRunning   : Bool  { get{ return horizontal_state == .Accelerating  || horizontal_state == .Decelerating   }}
    var alive       : Bool { get{ return !dead }}
    
    override init(name : String, texture : String, fragmentType : FragmentType){
        self.topSpeed = float2(30,30)
        self.acc = float2(30,30)
        
        super.init(name: name, texture: texture, fragmentType: fragmentType)
        self.dynamic = true
        self.can_rest = false
        SkeletonMap.getHandler(self)?.updateBuffer(0, ani: animation_state)

    }
    
    override func update(dt : Float, currentTime : Float){
        if self.rect.origin.y < -5  && !self.dead{
            self.died()
        }
        
        //TopSpeed
        if abs(velocity.x) > topSpeed.x {
            velocity.x = Float(Math.sign(velocity.x)) * min(abs(velocity.x), topSpeed.x)
        }
        if abs(velocity.y) > topSpeed.y {
            velocity.y = Float(Math.sign(velocity.y)) * min(abs(velocity.y), topSpeed.y)
        }
        
        try_moveBy(float3(velocity.x * dt, velocity.y * dt, 0))
    }
    
    override func try_moveBy(offset : float3) {
        self.current_rect.origin = self.rect.origin
        self.rect.origin += offset.xy
        contactState.reset()
    }
    func try_moveTo(offset : float3) {
        self.current_rect.origin = self.rect.origin
        self.rect.origin += offset.xy
        contactState.reset()
    }
    
    override func updateToNextRect(){
        
        moveTo(self.rect.origin.xyz)
    
        if contactState.squashed() {
            print("squashed")
            died()
            return
        }
        
        if onGround {
            if velocity.x == 0 && horizontal_state == .Decelerating{
                horizontal_state = .None
            }
        }
        
        if children != nil {
            let offset = self.rect.origin - self.current_rect.origin
            for c in children! {
                c.try_moveBy(offset.xyz)
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
        let skeletonHandler = SkeletonMap.getHandler(self)
    
        skeletonHandler?.updateBuffer(dt, ani: animation_state)
    }
    
    override func getAnimationState() -> AnimationType {
//        if onGround && horizontal_state == .None{
//            return .Resting
//        } else if onGround && isRunning {
//            return .Running
//        } else if !onGround {
//            if velocity.y > 0 {
//                return .Jumping
//            } else {
//                return .Falling
//            }
//        }
        return .Unknown
    }
    
    
    func setDirection(dir : Direction){
        if dir != direction {
            self.renderingObject?.rotateYInPlace(180)
        }
        direction = dir
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
        self.delegate?.modelDidChangePosition(self)
        
    }

    override func moveBy(offset : float3) {
        super.moveBy(offset)
        self.delegate?.modelDidChangePosition(self)
    }
    
    override func positionDidSet(){
        self.delegate?.modelDidChangePosition(self)
    }
    
    func died(){
        guard self.dead == false else {
            print("Can't die twice")
            return
        }
        self.delegate?.modelWillDie(self)
        
        self.dead = true
        
    }
    
    func removeChild(child : Model){
        guard self.children != nil else {
            print("ERROR, can't remove child from parent with no children")
            return
        }
        let i = children!.indexOf { (m) -> Bool in m === child }
        if i != nil {
            children!.removeAtIndex(i!)
        } else {
            print("ERROR, child can't be found")
        }
        child.parent = nil
    }
    
    func didIntersectWithObject(o : Object, side : Direction){
        if side == .Top && o.isParentable && !(self is Shell) {
            o.children?.append(self)
            self.parent = o
        }
    }

    func didIntersectWithModel(m : Model, side : Direction, vector : float2){
        
    }
    
    func checkIntersectWithRect(o : Object, dt : Float){
        let md = o.rect.minkowskiDifference(self.rect)

//        var handled = false
        if md.isAtOrigo() {
            var md_ret = md.closestPointOnBoundsToOrigin()
            CollisionMisc.checkCollision(&md_ret, bits: o.collision_side_bit)
            
            if md_ret.side != .None && (md_ret.penetration_vector.x != 0 || md_ret.penetration_vector.y != 0) {
//                handled = true
                if o is Model {
                    //first handles the penetrationvector
                    print("\(self) collide \(o)")
                    didIntersectWithModel((o as! Model), side: md_ret.side, vector: md_ret.penetration_vector)
                    md_ret.side.opposite()
                    (o as! Model).didIntersectWithModel(self, side: md_ret.side, vector: float2(0,0))
                } else {
                    let didIntersect = o.modelDidIntersect(self, side: md_ret.side, penetration_vector: md_ret.penetration_vector)
                    
                    if didIntersect {
                        self.didIntersectWithObject(o, side: md_ret.side)
                    }
                }
            }
        }
        //WARNING, no tunneling check
        return
//        if !handled {
//            
//            //WARNING o.current_rect?
//            md = o.current_rect.minkowskiDifference(self.current_rect)
//            var relativeMotion = self.velocity * dt
//            if o is Model {
//                let m = o as! Model
//                relativeMotion = (self.velocity - m.velocity) * dt
//            }
//            
//            var md_ret = md.getRayIntersectionFraction(float2(0,0), directionA: relativeMotion)
//            
//            //WARNING, cant check for epsilon? seems ok now though!
//            if md_ret.h < Float.infinity && md_ret.h > 0.000001{
//                
//                CollisionMisc.checkCollision(&md_ret, bits: o.collision_side_bit)
//                CollisionMisc.collisionsAgaintsVelocity(&md_ret, velocity:self.velocity)
//                
//                if md_ret.side != .None {
//                    let h = md_ret.h
//                    
//                    if o is Model {
//                        let m = o as! Model
//                        m.rect.origin = m.current_rect.origin + (m.velocity * dt * h)
//                        
//                        didIntersectWithModel(m, side: md_ret.side, vector: -(m.velocity * dt * h))
//                        
//                    } else {
//                        var penetration_vector = float2(0, 0)
//                        
//                        if md_ret.side == .Left || md_ret.side == .Right {
//                            penetration_vector = float2(0, (-self.velocity.x * dt * (1-h)))
//                        } else {
//                            penetration_vector = float2(0, (-self.velocity.y * dt * (1-h)))
//                        }
//                        
//                        let didIntersect = o.modelDidIntersect(self, side: md_ret.side, penetration_vector: penetration_vector)
//                        if didIntersect {
//                            self.didIntersectWithObject(o, side: md_ret.side)
//                        }
//                    }
//                }
//            }
//        }
    }
    
    

    
}
