//
//  Mehs.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import Metal

class Mesh {
    
    var vertexBuffer    : MTLBuffer?
    var indexBuffer     : MTLBuffer?
    var texture         : MTLTexture?
    var hitbox          : Box?
    
    init(name : String, renderer : Renderer){

        let url = NSBundle.mainBundle().URLForResource(name, withExtension: "obj")
        
        if url == nil {
            print("ERROR url with name \(name) couldn't be found. Aborting Mesh init")
            return
        }
        
        let objModel = OBJModel()
        hitbox = objModel.parseModel(url!)
        let group = objModel.groups[1]

        vertexBuffer = renderer.newBufferWithBytes(group.vertexData!.bytes, length: group.vertexData!.length)
        indexBuffer = renderer.newBufferWithBytes(group.indexData!.bytes, length: group.indexData!.length)

        texture = renderer.newTexture("\(name).png")!
    }
}