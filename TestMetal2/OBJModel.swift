//
//  OBJModel.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

struct FaceVertex : Hashable, Equatable{
    let vi : UInt16
    let ti : UInt16
    let ni : UInt16
    
    var hashValue : Int {
        get {
            // DJB Hash Function
            var hash = 5381
            
            hash = ((hash << 5) &+ hash) &+ Int(vi)
            hash = ((hash << 5) &+ hash) &+ Int(ti)
            hash = ((hash << 5) &+ hash) &+ Int(ni)
            return hash
        }
    }

}
func ==(lhs: FaceVertex, rhs: FaceVertex) -> Bool{
    return lhs.vi == rhs.vi && lhs.ti == rhs.ti && lhs.ni == rhs.ni
}
func <(v0: FaceVertex, v1: FaceVertex) -> Bool{
    if v0.vi < v1.vi {
        return true
    } else if (v0.vi > v1.vi) {
        return false;
    } else if (v0.ti < v1.ti){
        return true;
    } else if (v0.ti > v1.ti){
        return false;
    } else if (v0.ni < v1.ni){
        return true;
    } else if (v0.ni > v1.ni){
        return false;
    } else {
        return false;
    }
}

typealias IndexType = UInt16

struct OBJGroup {
    let name : String
    var vertexData : NSData?
    var indexData : NSData?
    
    init(name _name : String){
        name = _name
    }
}

class OBJModel {
    var vertices = [float4]()
    var normals = [float3]()
    var texCoords = [float2]()
    
    var groups = [OBJGroup]()
    var groupVertices = [Vertex]()
    var groupIndicies = [IndexType]()
    var vertexToGroupIndexMap = [FaceVertex : IndexType]()
    var currentGroup : OBJGroup?
    
    
    func beginGroupWithName(name : String){
        self.endCurrentGroup()
        
        currentGroup = OBJGroup(name: name)
    }
    
    func endCurrentGroup(){
        if currentGroup != nil {
            
            let vdata = NSMutableData()
            for vert in groupVertices {
                vdata.appendData(vert.toData())
            }
            let iData = NSData(bytes: &groupIndicies, length: sizeof(IndexType) * groupIndicies.count)
            currentGroup!.vertexData = vdata
            currentGroup!.indexData = iData
            groups.append(currentGroup!)
            
            groupIndicies.removeAll()
            groupVertices.removeAll()
            vertexToGroupIndexMap.removeAll()
            
            currentGroup = nil
        }
    }
    
    func importStrings(vertices_string : String, indices_and_normals_string : String, normals_string : String, transform : String, tex_string : String, skin : [Vertex]?) -> (Box, float4x4, Int){
        var vertices = [Vertex]()
        var indicies = [IndexType]()
        var normals  = [float3]()
        var matrix = float4x4()
        var tex_coords = [float2]()
        var tex_coords_check = [String : Int]()
        
        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        
        var scanner = NSScanner(string: vertices_string)
        scanner.charactersToBeSkipped = skipSet
        
        beginGroupWithName("test")
        
        var min_x : Float  = 0.0
        var min_y : Float  = 0.0
        var min_z : Float  = 0.0
        
        var max_x : Float  = 0.0
        var max_y : Float  = 0.0
        var max_z : Float  = 0.0
        
        
        while !scanner.atEnd {
            var x : Float = 0
            var y : Float = 0
            var z : Float = 0
            
            scanner.scanFloat(&x)
            scanner.scanFloat(&y)
            scanner.scanFloat(&z)
            
            let position = float4(x, y, z, 1)
            
            min_x = min(min_x, position.x)
            min_y = min(min_y, position.y)
            min_z = min(min_z, position.z)
            
            max_x = max(max_x, position.x)
            max_y = max(max_y, position.y)
            max_z = max(max_z, position.z)
            
            let vertex = Vertex(position: position, normal: float3(), texCoords: float2())
            vertices.append(vertex)
        }

        scanner = NSScanner(string: normals_string)
        scanner.charactersToBeSkipped = skipSet
        
        while !scanner.atEnd {
            var x : Float = 0
            var y : Float = 0
            var z : Float = 0
            
            scanner.scanFloat(&x)
            scanner.scanFloat(&y)
            scanner.scanFloat(&z)
            
            let vertex = float3(x, y, z)
            normals.append(vertex)
        }
        
        scanner = NSScanner(string: tex_string)
        scanner.charactersToBeSkipped = skipSet
        var nr_duplicates = 0
        while !scanner.atEnd {
            var s : Float = 0
            var t : Float = 0
            
            scanner.scanFloat(&s)
            scanner.scanFloat(&t)
            
            let tex = float2(s,t)
            tex_coords.append(tex)
            if tex_coords_check["\(s) \(t)"] != 1 {
                nr_duplicates += 1
            }
            tex_coords_check["\(s) \(t)"] = 1
        }
        print("Nr of duplicated tex_coords found: \(nr_duplicates)")
        
        scanner = NSScanner(string: indices_and_normals_string)
        scanner.charactersToBeSkipped = skipSet
        
        var new_vertex_buffer = [(Vertex, Int)]()
        
        var normal_buffer = [Int : float3]()
        while !scanner.atEnd {
            
            for _ in 0..<3 {
                var vi : Int32 = 0
                var ni : Int32 = 0
                var ti : Int32 = 0
                
                scanner.scanInt(&vi)
                scanner.scanInt(&ni)
                scanner.scanInt(&ti)
                
                indicies.append(IndexType(new_vertex_buffer.count))
                let vert = Vertex(position: vertices[Int(vi)].position, normal: normals[Int(ni)], texCoords: tex_coords[Int(ti)])
                new_vertex_buffer.append((vert, Int(vi)))
                normal_buffer[Int(vi)] = vert.normal + (normal_buffer[Int(vi)] == nil ? float3() : normal_buffer[Int(vi)]!)
//
//                indicies.append(IndexType(vi))
//                vertices[Int(vi)].normal += normals[Int(ni)]
//                vertices[Int(vi)].texCoords = tex_coords[Int(ti)]
            }
        }
        
        vertices.removeAll()
        for var (v,i) in new_vertex_buffer {
            var normal = normal_buffer[i]!
            let length = normal.length()
            normal = normal / length
            if skin != nil {
                let skin_v = skin![i]
                v.bone1 = skin_v.bone1
                v.bone2 = skin_v.bone2
                v.weight1 = skin_v.weight1
                v.weight2 = skin_v.weight2
            }
            v.normal = normal
            vertices.append(v)
        }
        
        
//        for var v in vertices {
//            var normal = v.normal
//            let length = normal.length()
//            normal = normal / length
//            v.normal = normal
//        }
        
        
        
        
        
        if transform.characters.count == 0 {
            matrix = Matrix.Identity()
        } else{
            matrix = Matrix.parseMatrix(transform)
        }
        groupVertices = vertices
        groupIndicies = indicies

        
        let origin = float3(min_x, min_y, min_z)
        let width = max_x - min_x
        let height = max_y - min_y
        let depth = max_z - min_z
        
        let hitbox = Box(origin: origin, width: width, height: height, depth: depth)
        
        return (hitbox, matrix, new_vertex_buffer.count)
        
    }
}