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
    static let shared = Graphics()
    var renderer    = Renderer()
    var meshes      = [String : Mesh]()
    let camera      = Camera()
    var hitboxBuffer : MTLBuffer?
    
    init() {
    
    }
    
    func start(layer : CAMetalLayer){
        camera.setFrustum((Float(layer.bounds.width)/2)/Settings.zoomFactor, top: (Float(layer.bounds.height)/2)/Settings.zoomFactor)
        camera.aspect = Float(layer.frame.width / layer.frame.height)
        renderer.metalLayer = layer
        renderer.initilize()
        
        if Settings.drawHitBox {
            updateHitboxBuffer()
        }
    }
    
    
    func updateUniforms(inout uniformBuffer : MTLBuffer?, transform : float4x4){
        
        var uniform = camera.getUniform(transform)
        if uniformBuffer == nil {
            uniformBuffer = self.renderer.newBufferWithBytes(&uniform, length: sizeof(Uniforms))
        } else{
            memcpy(uniformBuffer!.contents(), &uniform, sizeof(Uniforms));
        }
        
    }
    
    func addModel(name : String) -> Mesh{
        var mesh : Mesh? = meshes[name]
        if mesh == nil {
            print("Add new mesh for \(name)")
            mesh = Mesh(name: name, renderer: self.renderer, animations: Settings.animations[name])
            meshes[name] = mesh
        }
        
        return mesh!
    }
    
    func redraw(models : [Object]){
        autoreleasepool {
            if !self.renderer.startFrame() {
                return
            }
            for m in models {
                
                if m.renderingObject != nil {
                    let mesh = meshes[m.renderingObject!.mesh_key]
                    updateUniforms(&m.uniformBuffer, transform: m.renderingObject!.transform)
                    let texture = TextureHandler.shared[m.renderingObject?.textureName]
                    self.renderer.drawMesh(mesh!, uniformBuffer: m.uniformBuffer!, texture: texture)
                    
                    if Settings.drawHitBox {
                        drawHitBox(m)
                    }
                }
            }
            
            self.renderer.endFrame()
        }
    }
    
    func drawHitBox(m : Object){
        var hb_trans = Matrix.Identity()
        hb_trans[0].x = m.hitbox!.width
        hb_trans[1].y = m.hitbox!.height
        hb_trans[3].x = m.hitbox!.origin.x
        hb_trans[3].y = m.hitbox!.origin.y
        hb_trans[3].z = 10
        updateUniforms(&m.renderingObject!.hitboxUniformBuffer, transform: hb_trans)
        
        self.renderer.drawLineMesh(hitboxBuffer!, uniformBuffer: m.renderingObject!.hitboxUniformBuffer!, nrOfVertices: 8)
    }
    
    func updateHitboxBuffer(){
        var data = hitboxBufferData()
        if hitboxBuffer == nil {
            hitboxBuffer = self.renderer.newBufferWithBytes(data.bytes, length: data.length)
        } else {
            memcpy(hitboxBuffer!.contents(), &data, data.length)
        }
    }
    
    func hitboxBufferData() -> NSData{
        let vertex_data = NSMutableData()
        
        let vert1 = Vertex(position: float4(0, 0, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        let vert2 = Vertex(position: float4(1, 0, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        
        let vert3 = Vertex(position: float4(1, 0, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        let vert4 = Vertex(position: float4(1, 1, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        
        let vert5 = Vertex(position: float4(1, 1, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        let vert6 = Vertex(position: float4(0, 1, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        
        let vert7 = Vertex(position: float4(0, 1, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        let vert8 = Vertex(position: float4(0, 0, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
        
        vertex_data.appendData(vert1.toData())
        vertex_data.appendData(vert2.toData())
        vertex_data.appendData(vert3.toData())
        vertex_data.appendData(vert4.toData())
        vertex_data.appendData(vert5.toData())
        vertex_data.appendData(vert6.toData())
        vertex_data.appendData(vert7.toData())
        vertex_data.appendData(vert8.toData())
        
        return vertex_data
    }
    
}