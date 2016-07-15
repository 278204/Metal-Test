//
//  RenderingObject.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-15.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class RenderingObject {
    var offset = Matrix.Identity()
    var transform  = Matrix.Identity()
    var uniformBuffer : MTLBuffer?
    var hitboxUniformBuffer : MTLBuffer?

    var textureID : Int
    let meshID : Int
    
    init(mesh_key mk : String, textureName tn : String, fragmentType : FragmentType){
        textureID = TextureHandler.shared.newTexture(tn)
        
        let (_, index) = Graphics.shared.addModel(mk, fragmentType: fragmentType)
        meshID = index
    }
    
    func setNewTexture(tn : String) {
        textureID = TextureHandler.shared.newTexture(tn)
    }
    
    func resetPosition(hitbox : Box){
        let x = (hitbox.origin.x + hitbox.width/2)
        let y = (hitbox.origin.y + hitbox.height/2)
        let z = (hitbox.origin.z + hitbox.depth/2)
        setTranslation(float3(x,y,z))
    }
    
    func update(dt : Float){
//        skeleton?.runAnimation(dt)
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
    
    func rotateZInPlace(degrees : Float){
        let rotate_mat = Matrix.rotationZ(degrees)
        self.rotateInPlace(rotate_mat)
    }
    func rotateYInPlace(degrees : Float){
        let rotate_mat = Matrix.rotationY(degrees)
        self.rotateInPlace(rotate_mat)
    }
    func rotateInPlace(rotate_mat : float4x4){
        var translation1 = Matrix.Identity()
        translation1[3] = -transform[3]
        translation1[3][3] = 1
        var translation2 = Matrix.Identity()
        translation2[3] = transform[3]
        
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
        
        self.transform = offset * self.transform
    }
    
    func scale(scale : Float){
        let mat = float4x4(diagonal: float4(scale, scale, scale, 1))
        self.transform = mat * self.transform
    }
    
    func setOffset(off : float4){
        offset[3] = off
    }
    func scaleXInPlace(scale : Float){
        scaleInPlace(float4(scale,1,1,1))
    }
    func scaleYInPlace(scale : Float){
        scaleInPlace(float4(1,scale,1,1))
    }
    func scaleZInPlace(scale : Float){
        scaleInPlace(float4(1,1,scale,1))
    }
    func scaleXZInPlace(scale : Float){
        scaleInPlace(float4(scale,1,scale,1))
    }
    func scaleInPlace(scale : float4){
        var translation1 = Matrix.Identity()
        translation1[3] = -transform[3]
        translation1[3][3] = 1
        var translation2 = Matrix.Identity()
        translation2[3] = transform[3]
        
        let scale_mat = float4x4(diagonal: scale)
        self.transform = translation2 * scale_mat * translation1 * self.transform
    }
//    func skeletonDidChangeAnimation(skeleton : Skeleton) {
//        let skeleton_matrices = skeleton.getSkeletonData()
//        memcpy(skeletonBuffer!.contents(), skeleton_matrices.bytes, skeleton_matrices.length);
//    }
}