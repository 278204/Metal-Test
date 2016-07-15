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
    var mesh_map    = [String : Int]()
    var meshes      = [Mesh]()
    let camera      = Camera()
    var hitboxBuffer : MTLBuffer?
    var hitboxMesh : HitboxMesh?
    var started = false
    
    init() {

    }
    
    func start(layer : CAMetalLayer){
        renderer.metalLayer = layer
        
        if !started {
            started = true
            camera.setFrustum((Float(layer.bounds.width)/2)/Settings.zoomFactor, top: (Float(layer.bounds.height)/2)/Settings.zoomFactor)
            camera.aspect = Float(layer.frame.width / layer.frame.height)
            print("Layer size \(layer.bounds.size)")
            renderer.initilize()
            
            if Settings.drawHitBox {
                 hitboxMesh = HitboxMesh(renderer:self.renderer)
            }
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
    
    func addModel(name : String, fragmentType : FragmentType) -> (mesh : Mesh, index : Int){
//        var mesh : Mesh? = meshes[name]
//        if mesh == nil {
//            print("Add new mesh for \(name)")
//            mesh = Mesh(name: name, renderer: self.renderer, animations: Settings.animations[name], fragmentType: fragmentType)
//            meshes[name] = mesh
//        }
//        
//        
//        return mesh!
        
        var index = mesh_map[name]
        if index == nil {
            print("Add new mesh for \(name)")
            
            var mesh : Mesh?
            if name == "Grid" {
                mesh = GridMesh(renderer: self.renderer)
            } else {
                mesh = Mesh(name: name, renderer: self.renderer, animations: Settings.animations[name], fragmentType: fragmentType)
            }
            
            index = meshes.count
            mesh_map[name] = index
            meshes.append(mesh!)
        }
        return (meshes[index!], index!)
    }
    
    func startFrame(){
        if !self.renderer.startFrame() {
            return
        }
    }
    func redraw(models : [Object] /*quadTree : QuadTree*/){
//        autoreleasepool {
        

            let cam_center = -camera.position.xy
            let camAABB = AABB(origin: cam_center - (camera.frustumSize*0.5), size: camera.frustumSize)
            for m in models {
//                let m_center = m.rect.mid
//                let dist = m_center - cam_center
                if m.rect.intersects(camAABB) {
//                if dist.lengthSq() < camera.frustumSize.x*camera.frustumSize.x {
                    if m.renderingObject != nil {
                        let mesh = meshes[m.renderingObject!.meshID]
                    
                        updateUniforms(&m.uniformBuffer, transform: m.renderingObject!.transform)
                        let texture = TextureHandler.shared.getTexture(m.renderingObject?.textureID)
                        let skelHand = SkeletonMap.getHandler(m)
                        let skelBuffer = skelHand!.getBuffer(m.animation_state)
                        self.renderer.drawMesh(mesh, skeletonBuffer: skelBuffer, uniformBuffer: m.uniformBuffer!, texture: texture)
                        
                        if Settings.drawHitBox {
                            drawHitBox(m.rect, uniformBuffer: m.renderingObject!.hitboxUniformBuffer, skelBuffer: skelBuffer)
                        }
                    }
                }
            }
            
//            if Settings.drawHitBox {
//                let nodes = quadTree.getNodes()
//                for n in nodes {
//                    drawHitBox(n.bounds, uniformBuffer: n.uniformBuffer)
//                }
//            }
//            
        
//        }
    }
    func endFrame(){
        self.renderer.endFrame()
    }
    
    func drawHitBox(rect : AABB, var uniformBuffer : MTLBuffer?, skelBuffer : MTLBuffer?){
        var hb_trans = Matrix.Identity()
        hb_trans[0].x = rect.width
        hb_trans[1].y = rect.height
        hb_trans[3].x = rect.x
        hb_trans[3].y = rect.y
        hb_trans[3].z = 10
        updateUniforms(&uniformBuffer, transform: hb_trans)
        let texture = TextureHandler.shared.getTexture("Texture2.png")
        self.renderer.drawMesh(hitboxMesh!, skeletonBuffer: skelBuffer!, uniformBuffer: uniformBuffer!, texture: texture)
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