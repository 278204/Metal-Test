//
//  Object.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

struct CollisionBitmask {
    static let Object : UInt8 = 1
    static let Enemy : UInt8  = 1<<1
    static let Player : UInt8 = 1<<2
    
    static let All : UInt8 = 0b11111111
}


class Object{
    
    var id : Int = 0
    var children : [Model]?
    var isParentable : Bool { get { return children != nil } }
    
    var hitbox  : Box?
    var rect : AABB = AABB(rect: CGRectZero)
    var uniformBuffer : MTLBuffer?
    let renderingObject : RenderingObject?
    var can_rest = false
    var collision_side_bit : UInt8 = 0b0000 {didSet{collisionSideBitDidChange()}}
    var collision_bitmask : UInt8 = CollisionBitmask.All
    var collision_type : UInt8 = CollisionBitmask.Object
    var animation_state     : AnimationType { get { return getAnimationState() }}
    var dynamic = false
    var current_rect = AABB(rect: CGRectZero)
    var gridPos = GridPoint(x:0, y:0)
    
    init(name : String, texture : String, fragmentType : FragmentType){
        renderingObject = RenderingObject(mesh_key: name, textureName: texture, fragmentType: fragmentType)
        self.hitbox = Graphics.shared.meshes[renderingObject!.meshID].hitbox
//        if self.hitbox != nil {
//            self.resetToOrigin()
//        }
//        
        self.didUpdateHitbox()
        let mesh = Graphics.shared.meshes[self.renderingObject!.meshID]
        SkeletonMap.setSkeleton(self, skel: mesh.skeleton)
        
    }
    
    func update(dt : Float, currentTime : Float){
        
    }
    
    func try_moveBy(offset : float3) {
        self.rect.origin += offset.xy
    }
    
    func updateToNextRect(){
        let offset = self.rect.origin - self.current_rect.origin
        self.rect.origin = self.current_rect.origin
        moveBy(offset.xyz)
        
        
        if children != nil {
            for c in children! {
                c.try_moveBy(offset.xyz)
            }
        }
    }
    
    func positionDidSet(){
        
    }
    func collisionSideBitDidChange(){
        
    }
    func getAnimationState() -> AnimationType {
        return .Unknown
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
        self.renderingObject?.rotateZ(degrees)
    }
    func rotateZInPlace(degrees : Float){
        self.renderingObject?.rotateZInPlace(degrees)
    }
    
    func scale(scale : Float){
        hitbox?.origin.x    *= scale
        hitbox?.origin.y    *= scale
        hitbox?.width       *= scale
        hitbox?.height      *= scale
        self.renderingObject?.scale(scale)
        self.didUpdateHitbox()
    }
    func scaleXZ(scale : Float){
        self.renderingObject?.scaleXZInPlace(scale)
        hitbox?.height      *= scale
        self.didUpdateHitbox()
    }
    
    func moveBy(offset : float3) {
//        print("move by \(offset)")
        renderingObject?.translate(offset)
        
//        var pos = position
//        pos += offset
//        position = pos

        hitbox?.origin += offset
        self.rect.origin += offset.xy
        
//        self.current_rect.origin = self.rect.origin
    }
    
    func moveTo(pos : float3){
        
        renderingObject?.setTranslation(float3(pos.x + rect.width/2, pos.y + rect.height/2, pos.z))
        
//        position = pos
        hitbox?.origin.x = pos.x //- hitbox!.width/2
        hitbox?.origin.y = pos.y //- hitbox!.height/2
        rect.origin.x = hitbox!.origin.x
        rect.origin.y = hitbox!.origin.y
        
//        self.current_rect.origin = self.rect.origin
    }
    
    func didUpdateHitbox(){
        self.rect.origin = hitbox!.origin.xy
        self.rect.width = hitbox!.width
        self.rect.height = hitbox!.height
        self.current_rect.origin = self.rect.origin
        self.current_rect.width = self.rect.width
        self.current_rect.height = self.rect.height
    }
    
    func resetToOrigin(){
        hitbox!.origin.x = -hitbox!.width/2
        hitbox!.origin.y = -hitbox!.height/2
        hitbox!.origin.z = -hitbox!.depth/2
        
//        self.position = float3(0,0,0)
        
        renderingObject?.resetPosition(hitbox!)
        
        rect.origin = hitbox!.origin.xy
        rect.width = hitbox!.width
        rect.height = hitbox!.height
        self.current_rect.origin = self.rect.origin
    }
    
    func modelDidIntersect(model : Model, side : Direction, penetration_vector : float2) -> Bool{
        model.rect.origin += penetration_vector
        return true
    }
}