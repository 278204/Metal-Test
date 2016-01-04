//
//  Model.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import Metal
import simd

protocol ModelDelegate {
    func wantsRenderer() -> Renderer
}
class Model{
    
    var vertexBuffer : MTLBuffer?
    var indexBuffer : MTLBuffer?
    var uniformBuffer : MTLBuffer?
    let objModel : OBJModel
    var delegate : ModelDelegate?
    
    var transform : float4x4
    var position : float3 = float3(0,0,0)
    var texture : MTLTexture?
    
    init(name : String, delegate del : ModelDelegate){
        objModel = OBJModel()
        delegate = del
        transform = GameViewController.Identity()
        loadModel(name)
    }
    
    func loadModel(name : String){
        let url = NSBundle.mainBundle().URLForResource(name, withExtension: "obj")
        
        if url == nil {
            print("ERROR url with name \(name) couldn't be found. Aborting loadModel()")
            return
        }
        
        objModel.parseModel(url!)
        
        let group = objModel.groups[1]
        
        self.vertexBuffer = self.delegate!.wantsRenderer().newBufferWithBytes(group.vertices!, length: sizeof(Vertex) * group.vertexCount)
        self.indexBuffer = self.delegate!.wantsRenderer().newBufferWithBytes(group.indicies!, length: sizeof(IndexType) * group.indexCount)
        texture = self.delegate?.wantsRenderer().newTexture("spot_texture.png")
        
    }
    
    func moveBy(offset : float3) {
        position.x += offset.x
        position.y += offset.y
        position.z += offset.z
        transform[3].x = position.x
        transform[3].y = position.y
        transform[3].z = position.z
    }
}
