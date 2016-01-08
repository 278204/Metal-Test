//
//  Mehs.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import Metal
import simd
class Mesh : SkeletonDelegate {
    
    var vertexBuffer    : MTLBuffer?
    var indexBuffer     : MTLBuffer?
    var skeletonBuffer  : MTLBuffer?
    var texture         : MTLTexture?
    var hitbox          : Box?
    var transform       : float4x4?
    var skeleton        : Skeleton
    let renderer        : Renderer
    init(name : String, renderer r : Renderer){

        self.renderer = r
        let objModel = OBJModel()
        
        let dict = CPP_Wrapper().hello_cpp_wrapped(name) as! [String:AnyObject]
        
        let a = dict["geometry"] as! [String]
        
        let ret = objModel.importStrings(a[0] as String, indices_and_normals_string: a[2] as String, normals_string: a[1] as String, transform: a[3] as String, tex_string: a[4] as String)
        skeleton = Skeleton()
        skeleton.delegate = self
        skeleton.parseSkin(dict["skin"] as! [String : String], vertices: &objModel.groupVertices)
        skeleton.parseSkeleton(dict["skeleton"] as! [[[String : String]]])
        skeleton.parseAnimations(dict["animations"] as! [[String : String]])
        
        objModel.endCurrentGroup()

       
        hitbox = ret.0
        transform = ret.1
        let group = objModel.groups[0]
        
        let skel_data = getSkeletonData()
        vertexBuffer = renderer.newBufferWithBytes(group.vertexData!.bytes, length: group.vertexData!.length)
        indexBuffer = renderer.newBufferWithBytes(group.indexData!.bytes, length: group.indexData!.length)
        skeletonBuffer = renderer.newBufferWithBytes(skel_data.bytes, length: skel_data.length)
        texture = renderer.newTexture("Repave.jpg")!
    }
    
    func skeletonDidChangeAnimation() {
        let skeleton_matrices = getSkeletonData()
        memcpy(skeletonBuffer!.contents(), skeleton_matrices.bytes, skeleton_matrices.length);
    }
    
    func getSkeletonData() -> NSData{
        let skeleton_matrices = NSMutableData()
        for s in skeleton.skeleton where s != nil{
            var mat = s!.matrix
            skeleton_matrices.appendBytes(&mat, length: sizeof(float4x4))
        }
        return skeleton_matrices
    }
}