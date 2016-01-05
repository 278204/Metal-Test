//
//  3DGraphics.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class Graphics {
    
    var renderer    = Renderer()
    var meshes      = [String : Mesh]()
    let camera      = Camera()
    
    
    init() {
    
    }
    
    func start(layer : CAMetalLayer){
        renderer.metalLayer = layer
        renderer.initilize()
        
        camera.aspect = Float(layer.frame.width / layer.frame.height)
    }
    
    
    func updateUniforms(model : Model){
        
        var uniform = camera.getUniform(model.transform)
        if model.uniformBuffer == nil {
            model.uniformBuffer = self.renderer.newBufferWithBytes(&uniform, length: sizeof(Uniforms))
        } else{
            memcpy(model.uniformBuffer!.contents(), &uniform, sizeof(Uniforms));
        }
        
    }
    
    func addModel(name : String) -> Mesh{
        var mesh : Mesh? = meshes[name]
        if mesh == nil {
            print("Add new mesh for \(name)")
            mesh = Mesh(name: name, renderer: self.renderer)
            meshes[name] = mesh
        }
        
        return mesh!
    }
    
    func redraw(models : [Model]){
        
        self.renderer.startFrame()
        
        for m in models {
            
            let mesh = meshes[m.model_key]
            if mesh != nil {
                updateUniforms(m)
                self.renderer.drawMesh(mesh!, uniformBuffer: m.uniformBuffer!)
            }
        }
        
        self.renderer.endFrame()
    }
}