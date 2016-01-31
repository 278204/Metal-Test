//
//  RenderingObject.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-15.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class RenderingObject : SkeletonDelegate{
    var transform  = Matrix.Identity()
    var uniformBuffer : MTLBuffer?
    var hitboxUniformBuffer : MTLBuffer?
    var skeleton : Skeleton?        {   didSet{  skeleton?.delegate = self  }    }
    var skeletonBuffer : MTLBuffer?
    var textureName : String
    let mesh_key : String
    
    init(mesh_key mk : String, textureName tn : String){
        mesh_key = mk
        textureName = tn
        let mesh = Graphics.shared.addModel(mesh_key)
        self.skeleton = mesh.skeleton
        self.skeletonBuffer = mesh.skeletonBuffer
        self.skeleton?.delegate = self
        TextureHandler.shared.getTexture(tn)
    }
    
    func resetPosition(hitbox : Box){
        let x = (hitbox.origin.x + hitbox.width/2)
        let y = (hitbox.origin.y + hitbox.height/2)
        let z = (hitbox.origin.z + hitbox.depth/2)
        setTranslation(float3(x,y,z))
    }
    
    func update(dt : Float){
        skeleton?.runAnimation(dt)
    }
    
    func rotateY(y_delta : Float){
        let rotate_mat = Matrix.rotationY(y_delta)
        self.transform = rotate_mat * self.transform
    }
    
    
    func rotateX(y_delta : Float){
        let rotate_mat = Matrix.rotationX(y_delta)
        self.transform = rotate_mat * self.transform
    }
    
    func rotateZ(degrees : Float) {
        let rotate_mat = Matrix.rotationZ(degrees)
        self.transform = rotate_mat * self.transform
    }
    
    func rotateYInPlace(degrees : Float){
        var translation1 = Matrix.Identity()
        translation1[3] = -transform[3]
        translation1[3][3] = 1
        var translation2 = Matrix.Identity()
        translation2[3] = transform[3]
        
        let rotate_mat = Matrix.rotationY(degrees)
        self.transform = translation2 * rotate_mat * translation1 * self.transform
    }
    
    func translate(trans : float3){
        var mat = float4x4(diagonal: float4(1,1,1,1))
        mat[3].x = trans.x
        mat[3].y = trans.y
        mat[3].z = trans.z
        self.transform = mat * self.transform
    }
    
    func setTranslation(trans : float3){
        self.transform[3].x = trans.x
        self.transform[3].y = trans.y
        self.transform[3].z = trans.z
    }
    
    func scale(scale : Float){
        let mat = float4x4(diagonal: float4(scale, scale, scale, 1))
        self.transform = mat * self.transform
    }
    
    func scaleXInPlaye(scale : Float){
        var translation1 = Matrix.Identity()
        translation1[3] = -transform[3]
        translation1[3][3] = 1
        var translation2 = Matrix.Identity()
        translation2[3] = transform[3]
        
        let scale_mat = float4x4(diagonal: float4(scale, 1, 1, 1))
        self.transform = translation2 * scale_mat * translation1 * self.transform
    }
    func skeletonDidChangeAnimation(skeleton : Skeleton) {
        let skeleton_matrices = skeleton.getSkeletonData()
        memcpy(skeletonBuffer!.contents(), skeleton_matrices.bytes, skeleton_matrices.length);
    }
}