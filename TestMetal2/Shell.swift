//
//  PickupObject.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-02.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd


class PickupObject : WallBounceEnemy {
    var isPickedUp : Bool { get { return parent is Player }}
    
    func modelDidPush(m : Model){
        
    }
}

class Shell : PickupObject {

    var rotationZ : Float = 0
    init() {
        super.init(name: "Cube", texture: "Texture2.png", fragmentType: FragmentType.Texture)
        self.topSpeed   = float2(30,100)
        self.acc        = float2(30,40)
    }
    
    override func update(dt : Float, currentTime : Float){
        if !(parent is Player) {
            self.velocity.y += Float(Settings.gravity * mass) * dt
            self.velocity.x = acceleration.x
        }
        if rotationZ > 0 {
            self.rotateZInPlace(rotationZ)
        }
        super.update(dt, currentTime: currentTime)
    }
    
    override func died() {
        guard self.dead == false else {
            print("Can't die twice")
            return
        }
        super.died()
        self.velocity.x = 0
        rotationZ = 20
        if parent != nil {
            (self.parent! as! Model).removeChild(self)
        }
    }
    
    override func modelDidPush(m : Model) {
        self.collision_bitmask = CollisionBitmask.All
        if m.rect.mid.x < self.rect.mid.x {
            changeAcceleration(acc.x)
        } else {
            changeAcceleration(-acc.x)
        }
    }
    
    override func didIntersectWithModel(m: Model, side: Direction, vector : float2) {
        if m is Player{
            let p = m as! Player
            print("Player velocity \(m.velocity)")
            if side == .Bottom || (m.current_rect.y > self.rect.max.y && m.velocity.y < 0) {
                if velocity.x == 0 {
                    if p.canPickUp {
                        p.pickup(self)
                        self.collision_bitmask = CollisionBitmask.Enemy
                    } else {
                        modelDidPush(m)
                        m.contactState.setOnGround()
                        (m as! Player).jumpOffEnemy()
                        m.rect.origin -= vector
                    }
                } else {
                    changeAcceleration(0)
                    m.contactState.setOnGround()
                    (m as! Player).jumpStart()
                    m.rect.origin -= vector
                }
            } else if velocity.x == 0 {
                if !p.canPickUp {
                    modelDidPush(m)
                    m.velocity.x = 0
                    self.rect.origin += vector
                } else if p.direction == side{
                    p.pickup(self)
                    self.collision_bitmask = CollisionBitmask.Enemy
                }
                
            } else {
                m.died()
            }
            
        } else if velocity.x != 0{
            m.died()
        } else if isPickedUp {
            m.died()
            self.died()
            //WARNING, remove from parent?
        }
    }
    

}