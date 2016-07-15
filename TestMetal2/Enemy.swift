//
//  Enemy.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-01.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd
class Enemy : Model {
    
    
    override init(name: String, texture: String, fragmentType: FragmentType) {
        super.init(name: name, texture: texture, fragmentType: fragmentType)
        self.collision_type = CollisionBitmask.Enemy
    }
    
    override func died() {
        self.velocity.x = 0
        
        self.renderingObject?.scaleYInPlace(0.2)
        self.moveBy(float3(0, -self.rect.height*1.3, 0))
        self.can_rest = true
        super.died()
    }
    override func handleAnimations(dt : Float) {
        if !self.dead{
            super.handleAnimations(dt)
        }
    }
    
    override func getAnimationState() -> AnimationType {
        if dead{
            return AnimationType.Unknown
        } else {
            return .Running
        }
    }
    override func didIntersectWithModel(m: Model, side: Direction, vector : float2) {
        if m is Player {
            
            if (m.current_rect.y >= self.rect.max.y && m.velocity.y <= 0) {
                
                m.moveBy(float3(0,self.rect.max.y - m.rect.origin.y + 0.1,0))
                (m as! Player).jumpOffEnemy()
                self.died()
                
            } else {
                print("player \(m.current_rect) \(m.velocity.y)")
                print("ENemy \(self.rect.max) \(self.current_rect.max)")
                (m as! Player).diedFromEnemy()
            }
        } else {
            switch(side){
            case .Top:
                velocity.y = 0
                contactState.setOnGround()
                self.rect.origin += vector
            case .Right:
                velocity.x = 0
                changeAcceleration(acc.x)
                self.rect.origin += vector
            case .Left:
                velocity.x = 0
                changeAcceleration(-acc.x)
                self.rect.origin += vector
            case .Bottom:
                m.velocity.y = 0
                m.rect.origin += vector
            case .None:
                break
            }
        }
    }
}