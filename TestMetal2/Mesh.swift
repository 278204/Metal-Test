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

enum PrimativeType {
    case Triangle
    case Line
}
enum FragmentType : Int {
    case Texture = 0
    case TextureLight = 1
}
class Mesh{
    
    var vertexBuffer    : MTLBuffer?
    var indexBuffer     : MTLBuffer?
//    var skeletonBuffer  : MTLBuffer?
    var fragmentTypeBuffer : MTLBuffer?
    var hitbox          : Box?
//    var transform       : float4x4?
    var skeleton        : Skeleton
    var nr_vertices     : Int
    var primativeType = MTLPrimitiveType.Triangle
    
    init(){
        skeleton = Skeleton()
        nr_vertices = 0
    }
    init(name : String, renderer : Renderer, animations : [String]?, var fragmentType : FragmentType){

        skeleton = Skeleton()
        
        let objModel = OBJModel()
        let dict = CPP_Wrapper().hello_cpp_wrapped(name) as! [String:AnyObject]
        let a = dict["geometry"] as! [String]
        var vertices = [Vertex]()
        
        
        skeleton.parse(dict, vertices: &vertices)
        let ret = objModel.importStrings(a[0] as String, indices_and_normals_string: a[2] as String, normals_string: a[1] as String, transform: a[3] as String, tex_string: a[4] as String, skin: vertices)
        
        hitbox      = ret.0
//        transform   = ret.1
        nr_vertices = ret.2

        objModel.endCurrentGroup()

        let group = objModel.groups[0]
        
        let frag_data = NSData(bytes: &fragmentType, length: sizeof(FragmentType))
//        let skel_data = skeleton.getSkeletonData()
        vertexBuffer = renderer.newBufferWithBytes(group.vertexData!.bytes, length: group.vertexData!.length)
//        indexBuffer = renderer.newBufferWithBytes(group.indexData!.bytes, length: group.indexData!.length)
//        skeletonBuffer = renderer.newBufferWithBytes(skel_data.bytes, length: skel_data.length)
        fragmentTypeBuffer = renderer.newBufferWithBytes(frag_data.bytes, length: 4)
        
        if animations != nil {
            for s in animations! {
                let ani_file = "\(name)_\(s)"
                let animations = CPP_Wrapper().importAnimaiton(ani_file) as! [String:AnyObject]
                skeleton.parser?.parseAnimations(animations["animations"] as! [[String : String]], animation_name: s)
            }
        }
    }
}