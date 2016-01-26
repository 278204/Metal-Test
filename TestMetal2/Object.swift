//
//  Object.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class Object{
    var position : float3 = float3(0,0,0)   {didSet{    positionDidSet()    }}
    var hitbox  : Box?
    var rect : CGRect = CGRectZero
    
    var uniformBuffer : MTLBuffer?
    let renderingObject : RenderingObject?
    var dynamic : Bool
    var can_rest = false
    var collision_bit : UInt8 = 0b1111
    
    init(name : String, renderingObject ro : RenderingObject?){
        dynamic = false
        renderingObject = ro
    }
    
    func positionDidSet(){
        
    }
    
    func rotateY(degrees : Float){
        self.renderingObject?.rotateY(degrees)
        self.hitbox?.rotateY(-degrees)
        didUpdateHitbox()
    }
    func rotateX(degrees : Float){
        self.renderingObject?.rotateX(degrees)
        self.hitbox?.rotateX(degrees)
        didUpdateHitbox()
    }
    
    func rotateZ(degrees : Float) {
        self.renderingObject?.rotateX(degrees)
    }
    
    func scale(scale : Float){
        hitbox?.origin.x    *= scale
        hitbox?.origin.y    *= scale
        hitbox?.width       *= scale
        hitbox?.height      *= scale
        self.renderingObject?.scale(scale)
        self.didUpdateHitbox()
    }
    
    func moveBy(offset : float3) {
        
        renderingObject?.translate(offset)
        
        var pos = position
        pos.x += offset.x
        pos.y += offset.y
        pos.z += offset.z
        position = pos

        
        hitbox?.origin += offset
        self.rect.origin.x += CGFloat(offset.x)
        self.rect.origin.y += CGFloat(offset.y)
    }
    
    func moveTo(pos : float3){
        
        renderingObject?.setTranslation(pos)
        
        position = pos
        hitbox?.origin.x = pos.x - hitbox!.width/2
        hitbox?.origin.y = pos.y - hitbox!.height/2
        rect.origin.x = CGFloat(hitbox!.origin.x)
        rect.origin.y = CGFloat(hitbox!.origin.y)
    }
    
    func didUpdateHitbox(){
        self.rect.origin.x = CGFloat(hitbox!.origin.x)
        self.rect.origin.y = CGFloat(hitbox!.origin.y)
        self.rect.size.width = CGFloat(hitbox!.width)
        self.rect.size.height = CGFloat(hitbox!.height)
    }
    
    func resetToOrigin(){
        hitbox!.origin.x = -hitbox!.width/2
        hitbox!.origin.y = -hitbox!.height/2
        hitbox!.origin.z = -hitbox!.depth/2
        
        self.position = float3(0,0,0)
        
        renderingObject?.resetPosition(hitbox!)
        
        rect.origin.x = CGFloat(hitbox!.origin.x)
        rect.origin.y = CGFloat(hitbox!.origin.y)
        rect.size.width = CGFloat(hitbox!.width)
        rect.size.height = CGFloat(hitbox!.height)
    }
}