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
    var rect : AABB = AABB(rect: CGRectZero)
    var uniformBuffer : MTLBuffer?
    let renderingObject : RenderingObject?
    var dynamic : Bool
    var can_rest = false
    var collision_bit : UInt8 = 0b0000
    
    init(name : String, texture : String){
        dynamic = false
        renderingObject = RenderingObject(mesh_key: name, textureName: texture)
        self.hitbox = Graphics.shared.meshes[name]?.hitbox
        self.resetToOrigin()
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
//        print("move by \(offset)")
        renderingObject?.translate(offset)
        
        var pos = position
        pos += offset
        position = pos

        hitbox?.origin += offset
        self.rect.origin += offset.xy
    }
    
    func moveTo(pos : float3){
        
        renderingObject?.setTranslation(pos)
        
        position = pos
        hitbox?.origin.x = pos.x - hitbox!.width/2
        hitbox?.origin.y = pos.y - hitbox!.height
        rect.origin.x = hitbox!.origin.x
        rect.origin.y = hitbox!.origin.y
    }
    
    func didUpdateHitbox(){
        self.rect.origin = hitbox!.origin.xy
        self.rect.width = hitbox!.width
        self.rect.height = hitbox!.height
    }
    
    func resetToOrigin(){
        hitbox!.origin.x = -hitbox!.width/2
        hitbox!.origin.y = -hitbox!.height/2
        hitbox!.origin.z = -hitbox!.depth/2
        
        self.position = float3(0,0,0)
        
        renderingObject?.resetPosition(hitbox!)
        
        rect.origin = hitbox!.origin.xy
        rect.width = hitbox!.width
        rect.height = hitbox!.height
    }
    
    func checkCollision(inout md_ret : (penetration_vector : float2, side : Direction), bits : UInt8) {
        var reset = false
        switch(md_ret.1){
        case .Top:
            if bits & 0b1000 != 0 {
                reset = true
            }
        case .Right:
            if bits & 0b0100 != 0 {
                reset = true
            }
        case .Left:
            if bits & 0b0001 != 0 {
                reset = true
            }
        case .Bottom:
            if bits & 0b0010 != 0 {
                reset = true
            }
        case .None:
            md_ret.0 = float2(0,0)
        }
        if reset {
            md_ret.1 = .None
            md_ret.0 = float2(0,0)
        }
    }
    
    func checkCollision(inout md_ret : (h : Float, side : Direction), bits : UInt8) {
        var reset = false
        switch(md_ret.side){
        case .Top:
            if bits & 0b1000 != 0 {
                reset = true
            }
        case .Right:
            if bits & 0b0100 != 0 {
                reset = true
            }
        case .Left:
            if bits & 0b0001 != 0 {
                reset = true
            }
        case .Bottom:
            if bits & 0b0010 != 0 {
                reset = true
            }
        case .None:
            md_ret.0 = Float.infinity
        }
        if reset {
            md_ret.1 = .None
            md_ret.0 = Float.infinity
        }
    }
}