//
//  OBJModel.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

struct Vertex {
    let position : float4
    let normal : float4
//    let texCoords : float2
}

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
    var vertices : [Vertex]?
    var indicies : [IndexType]?
    var vertexCount : size_t
    var indexCount : size_t
    
    init(name _name : String){
        name = _name
        vertices = nil
        indicies = nil
        vertexCount = 0
        indexCount = 0
    }
}

class OBJModel {
    var vertices = [float4]()
    var normals = [float4]()
    var texCoords = [float2]()
    
    var groups = [OBJGroup]()
    var groupVertices = [Vertex]()
    var groupIndicies = [IndexType]()
    var vertexToGroupIndexMap = [FaceVertex : IndexType]()
    
    var currentGroup : OBJGroup?
    

    
    func parseModel(url : NSURL){
        var contents = ""
        do{
            contents = try String(contentsOfURL: url, encoding: NSASCIIStringEncoding)
        } catch{
            print("ERROR opening \(url)")
            return
        }
        
        let scanner = NSScanner(string: contents)
        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let consumeSet = skipSet.invertedSet
        let newlineSet = NSCharacterSet.newlineCharacterSet()
        
        scanner.charactersToBeSkipped = skipSet
        
        
        self.beginGroupWithName("(unnamed)")
        
        while !scanner.atEnd {
            var tokenPointer : NSString?
            if !scanner.scanCharactersFromSet(consumeSet, intoString: &tokenPointer) {
                print("scanner couldn't scan")
                break
            }
            
            if tokenPointer == nil {
                print("ERROR: Token is empty")
                break
            }
            let token : NSString = tokenPointer!
            
            if token.isEqualToString("v"){
                var x : Float = 0
                var y : Float = 0
                var z : Float = 0
                scanner.scanFloat(&x)
                scanner.scanFloat(&y)
                scanner.scanFloat(&z)
                
                let vertex = float4(x, y, z, 1)
                vertices.append(vertex)
                
            } else if token.isEqualToString("vt") {
                var u : Float = 0
                var v : Float = 0
                scanner.scanFloat(&u)
                scanner.scanFloat(&v)
                
                let texCoor = float2(u, v)
                texCoords.append(texCoor)
                
            } else if token.isEqualToString("vn") {
                var nx : Float = 0
                var ny : Float = 0
                var nz : Float = 0
                scanner.scanFloat(&nx)
                scanner.scanFloat(&ny)
                scanner.scanFloat(&nz)
                
                let normal = float4(nx, ny, nz, 0)
                normals.append(normal)
                
            } else if token.isEqualToString("f") {
                
                var faceVertices = [FaceVertex]()
                
                while true {
                    var viPointer : Int32 = 0
                    var tiPointer : Int32 = 0
                    var niPointer : Int32 = 0
                    
                    if !scanner.scanInt(&viPointer) {
                        break
                    }
                    
                    if scanner.scanString("/", intoString: nil) {
                        scanner.scanInt(&tiPointer)
                        if scanner.scanString("/", intoString: nil) {
                            scanner.scanInt(&niPointer)
                        }
                    }
                    
                    var vi = viPointer
                    var ti = tiPointer
                    var ni = niPointer
                    
                    vi = (vi < 0) ? (vertices.count + vi - 1) : (vi - 1)
                    ti = (ti < 0) ? (texCoords.count + ti - 1) : (ti - 1)
                    ni = (ni < 0) ? (vertices.count + ni - 1) : (ni - 1)
                    
                    let faceVertex = FaceVertex(vi: UInt16(vi), ti: UInt16(ti), ni: UInt16(ni))
                    faceVertices.append(faceVertex)
                }
                
                addFaceWithFaceVertices(faceVertices)
                
            } else if token.isEqualToString("g") {
                var groupName : NSString?
                if scanner.scanUpToCharactersFromSet(newlineSet, intoString: &groupName) {
                    self.beginGroupWithName(groupName! as String)
                }
            }
            
        }
        
        self.endCurrentGroup()
        
    }
    
    
    func beginGroupWithName(name : String){
        self.endCurrentGroup()
        
        currentGroup = OBJGroup(name: name)
        
        
    }
    
    func endCurrentGroup(){
        if currentGroup != nil {
            currentGroup!.vertexCount = groupVertices.count
            if currentGroup!.vertexCount > 0 {
                //WARNING: only copy address? and later removes all?
                currentGroup!.vertices = groupVertices
            }
            
            currentGroup!.indexCount = groupIndicies.count
            if currentGroup!.indexCount > 0 {
                //WARNING: only copy address? and later removes all?
                currentGroup!.indicies = groupIndicies
            }
            //WARNING: entry in array doesn't change in endCurrentGroup?
            groups.append(currentGroup!)
            print("End group \(groups.last?.name) \(groups.last?.indicies?.count)")
            groupIndicies.removeAll()
            groupVertices.removeAll()
            vertexToGroupIndexMap.removeAll()
            
            
            
            print("End group \(groups.last?.name) \(groups.last?.indicies?.count)")
            
            currentGroup = nil
        }
    }
    
    func addFaceWithFaceVertices(faceVertices : [FaceVertex]) {
        for var i = 0; i < faceVertices.count - 2; i++ {
            self.addVertexToCurrentGroup(faceVertices[0])
            self.addVertexToCurrentGroup(faceVertices[i+1])
            self.addVertexToCurrentGroup(faceVertices[i+2])
        }
    }
    
    func addVertexToCurrentGroup(fv : FaceVertex){
        let UP = float4(0,1,0,0)
        var groupIndex : UInt16 = 0
        
        let index = vertexToGroupIndexMap[fv]
        if index != nil {
            groupIndex = index!
        } else{
            let vertex = Vertex(position: vertices[Int(fv.vi)], normal: fv.ni > 0 ? normals[Int(fv.ni)] : UP/*, texCoords: fv.ti > 0 ? texCoords[Int(fv.ti)] : float2(0,0)*/)
            groupVertices.append(vertex)
            groupIndex = UInt16(groupVertices.count - 1)
            vertexToGroupIndexMap[fv] = groupIndex
        }
        
        groupIndicies.append(groupIndex)
    }
    
    
    
    
    
}