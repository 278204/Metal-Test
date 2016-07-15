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

        let vertex_data = NSMutableData()
        
        let nr_horizontal = Settings.maxGridPoint.y
        let nr_vertical = Settings.maxGridPoint.x
        for i in 0..<nr_horizontal{
            //Horizontal lines -
            let vert1 = Vertex(position: float4(0, Float(i) * Settings.gridSize, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            let vert2 = Vertex(position: float4(1000, Float(i) * Settings.gridSize, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            
            vertex_data.appendData(vert1.toData())
            vertex_data.appendData(vert2.toData())
        }
        for i in 0..<nr_vertical{
            //Vertical lines |
            let vert1 = Vertex(position: float4(Float(i) * Settings.gridSize, 0, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            let vert2 = Vertex(position: float4(Float(i) * Settings.gridSize, 500, 0, 1), normal: float3(0,0,0), texCoords:float2(0,0))
            
            vertex_data.appendData(vert1.toData())
            vertex_data.appendData(vert2.toData())
        }
    
        super.init()
        nr_vertices = (nr_horizontal + nr_vertical) * 2
    
        var fragmentType = FragmentType.Texture
        let frag_data = NSData(bytes: &fragmentType, length: sizeof(FragmentType))
        fragmentTypeBuffer = renderer.newBufferWithBytes(frag_data.bytes, length: 4)
        vertexBuffer = renderer.newBufferWithBytes(vertex_data.bytes, length: vertex_data.length)
        self.primativeType = .Line
        
        self.hitbox = Box(origin: float3(0,0,0), width: Float(nr_vertical) * Settings.gridSize, height: Float(nr_horizontal) * Settings.gridSize, depth : 0.0)


    }
}