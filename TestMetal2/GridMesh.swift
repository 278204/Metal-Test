//
//  GridMehs.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class GridMesh : Mesh {
    
    
    init(renderer : Renderer){
        var y_pos : Float = 0
        let vertex_data = NSMutableData()
        for _ in 0..<10{
            let vert1 = Vertex(position: float4(0, y_pos, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            let vert2 = Vertex(position: float4(1000, y_pos, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            
            vertex_data.appendData(vert1.toData())
            vertex_data.appendData(vert2.toData())
            y_pos += Settings.gridSize
        }
        for i in 0..<10{
            let vert1 = Vertex(position: float4(Float(i) * Settings.gridSize, 0, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            let vert2 = Vertex(position: float4(Float(i) * Settings.gridSize, 500, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            
            vertex_data.appendData(vert1.toData())
            vertex_data.appendData(vert2.toData())
        }
        
        super.init()
        nr_vertices = 20 * 2
        
        vertexBuffer = renderer.newBufferWithBytes(vertex_data.bytes, length: vertex_data.length)
    }
}