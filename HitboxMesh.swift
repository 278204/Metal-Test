//
//  GridMehs.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class HitboxMesh : Mesh {
    
    
    init(renderer : Renderer){
        
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
        
        
        super.init()
        nr_vertices = 8
        
        var fragmentType = FragmentType.Texture
        let frag_data = NSData(bytes: &fragmentType, length: sizeof(FragmentType))
        fragmentTypeBuffer = renderer.newBufferWithBytes(frag_data.bytes, length: 4)
        vertexBuffer = renderer.newBufferWithBytes(vertex_data.bytes, length: vertex_data.length)
        self.primativeType = .Line
        
        self.hitbox = Box(origin: float3(0,0,0), width: 1, height: 1, depth : 0.0)
        
        
    }
}