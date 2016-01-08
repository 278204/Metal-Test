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
    
//    //Skeleton stuff
//    var skeleton_parts : [String]?
//    var skeleton : [Joint?]?
//    var inv_bind_matrices = [float4x4]()
//    var bind_shape : float4x4? = Matrix.Identity()
//    var animations : [JointAnimation?]?
    
//    func parseModel(url : NSURL) -> Box?{
//        var contents = ""
//        do{
//            contents = try String(contentsOfURL: url, encoding: NSASCIIStringEncoding)
//        } catch{
//            print("ERROR opening \(url)")
//            return nil
//        }
//        
//        let scanner = NSScanner(string: contents)
//        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
//        let consumeSet = skipSet.invertedSet
//        let newlineSet = NSCharacterSet.newlineCharacterSet()
//        
//        var min_x : Float  = 0.0
//        var min_y : Float  = 0.0
//        var min_z : Float  = 0.0
//        
//        var max_x : Float  = 0.0
//        var max_y : Float  = 0.0
//        var max_z : Float  = 0.0
//        
//        scanner.charactersToBeSkipped = skipSet
//        
//        
//        self.beginGroupWithName("(unnamed)")
//        
//        while !scanner.atEnd {
//            var tokenPointer : NSString?
//            if !scanner.scanCharactersFromSet(consumeSet, intoString: &tokenPointer) {
//                print("scanner couldn't scan")
//                break
//            }
//            
//            if tokenPointer == nil {
//                print("ERROR: Token is empty")
//                break
//            }
//            let token : NSString = tokenPointer!
//            
//            if token.isEqualToString("v"){
//                var x : Float = 0
//                var y : Float = 0
//                var z : Float = 0
//                scanner.scanFloat(&x)
//                scanner.scanFloat(&y)
//                scanner.scanFloat(&z)
//                
//                min_x = min(min_x, x)
//                min_y = min(min_y, y)
//                min_z = min(min_z, z)
//                
//                max_x = max(max_x, x)
//                max_y = max(max_y, y)
//                max_z = max(max_z, z)
//                
//                let vertex = float4(x, y, z, 1)
//                vertices.append(vertex)
//                
//            } else if token.isEqualToString("vt") {
//                var u : Float = 0
//                var v : Float = 0
//                scanner.scanFloat(&u)
//                scanner.scanFloat(&v)
//                
//                let texCoor = float2(u, v)
//                texCoords.append(texCoor)
//                
//            } else if token.isEqualToString("vn") {
//                var nx : Float = 0
//                var ny : Float = 0
//                var nz : Float = 0
//                scanner.scanFloat(&nx)
//                scanner.scanFloat(&ny)
//                scanner.scanFloat(&nz)
//                
//                let normal = float3(nx, ny, nz)
//                normals.append(normal)
//                
//            } else if token.isEqualToString("f") {
//                
//                var faceVertices = [FaceVertex]()
//                
//                while true {
//                    var viPointer : Int32 = 0
//                    var tiPointer : Int32 = 0
//                    var niPointer : Int32 = 0
//                    
//                    if !scanner.scanInt(&viPointer) {
//                        break
//                    }
//                    
//                    if scanner.scanString("/", intoString: nil) {
//                        scanner.scanInt(&tiPointer)
//                        if scanner.scanString("/", intoString: nil) {
//                            scanner.scanInt(&niPointer)
//                        }
//                    }
//                    
//                    var vi = viPointer
//                    var ti = tiPointer
//                    var ni = niPointer
//                    
//                    vi = (vi < 0) ? (vertices.count + vi - 1) : (vi - 1)
//                    ti = (ti < 0) ? (texCoords.count + ti - 1) : (ti - 1)
//                    ni = (ni < 0) ? (vertices.count + ni - 1) : (ni - 1)
//                    
//                    let faceVertex = FaceVertex(vi: UInt16(vi), ti: UInt16(ti), ni: UInt16(ni))
//                    faceVertices.append(faceVertex)
//                }
//                
//                addFaceWithFaceVertices(faceVertices)
//                
//            } else if token.isEqualToString("o") || token.isEqualToString("g") {
//                var groupName : NSString?
//                if scanner.scanUpToCharactersFromSet(newlineSet, intoString: &groupName) {
//                    self.beginGroupWithName(groupName! as String)
//                }
//            }
//        }
//        
//        let origin = float3(min_x, min_y, min_z)
//        let width = max_x - min_x
//        let height = max_y - min_y
//        let depth = max_z - min_z
//        
//        let hitbox = Box(origin: origin, width: width, height: height, depth: depth)
//        hitbox.printOut()
//        
//   
//        
//        return hitbox
//    }
//    
    
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
    
    func addFaceWithFaceVertices(faceVertices : [FaceVertex]) {
        for var i = 0; i < faceVertices.count - 2; ++i {
            self.addVertexToCurrentGroup(faceVertices[0])
            self.addVertexToCurrentGroup(faceVertices[i+1])
            self.addVertexToCurrentGroup(faceVertices[i+2])
        }
    }
    
    func addVertexToCurrentGroup(fv : FaceVertex){
        let UP = float3(0,1,0)
        let ZERO2 = float2(0,0)
        
        var groupIndex : UInt16 = 0
        let INVALID_INDEX : UInt16 = 0xffff;
        
        let index = vertexToGroupIndexMap[fv]
        if index != nil {
            groupIndex = index!
        } else{
            var vertex = Vertex()
            vertex.position = vertices[Int(fv.vi)]
            vertex.normal   = fv.ni != INVALID_INDEX ? normals[Int(fv.ni)]   : UP
            vertex.texCoords = fv.ti != INVALID_INDEX ? texCoords[Int(fv.ti)] : ZERO2
    
            groupVertices.append(vertex)
            groupIndex = UInt16(groupVertices.count - 1)
            vertexToGroupIndexMap[fv] = groupIndex
        }
        
        groupIndicies.append(groupIndex)
    }
    
    
    
    func importStrings(vertices_string : String, indices_and_normals_string : String, normals_string : String, transform : String, tex_string : String) -> (Box, float4x4){
        var vertices = [Vertex]()
        var indicies = [IndexType]()
        var normals  = [float3]()
        var matrix = float4x4()
        var tex_coords = [float2]()
        
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
            
            min_x = min(min_x, x)
            min_y = min(min_y, y)
            min_z = min(min_z, z)
            
            max_x = max(max_x, x)
            max_y = max(max_y, y)
            max_z = max(max_z, z)
            
            let position = float4(x, y, z, 1)
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
        
        while !scanner.atEnd {
            var s : Float = 0
            var t : Float = 0
            
            scanner.scanFloat(&s)
            scanner.scanFloat(&t)
            
            let tex = float2(s,t)
            tex_coords.append(tex)
        }
        
        scanner = NSScanner(string: indices_and_normals_string)
        scanner.charactersToBeSkipped = skipSet
        
        while !scanner.atEnd {
            
            for _ in 0..<3 {
                var vi : Int32 = 0
                var ni : Int32 = 0
                var ti : Int32 = 0
                
                scanner.scanInt(&vi)
                scanner.scanInt(&ni)
                scanner.scanInt(&ti)
                
                indicies.append(IndexType(vi))
                
                vertices[Int(vi)].normal += normals[Int(ni)]
                
                vertices[Int(vi)].texCoords = tex_coords[Int(ti)]
            }

        }
        
        for var v in vertices {
            var normal = v.normal
            let length = normal.length()
            normal = normal / length
            v.normal = normal
            
        }
        
        
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
        
        return (hitbox, matrix)
        
    }
    
//    func parseSkin(skin : [String:String]){
//    
//        let name = skin["name"]!
//        
//        let weights_string = skin["weights"]!
//        let bind_shape_string = skin["bind_shape"]!
//        let joints_string = skin["joints"]!
//        let weight_indicies_string = skin["weights_indicies"]!
//        var inv_bind_matrix_string = skin["inv_bind_matrix"]!
//       
//        let inv_bind_array = inv_bind_matrix_string.componentsSeparatedByString("||");
//        inv_bind_matrix_string = inv_bind_array[1]
//        let inv_bind_count = Int(inv_bind_array[0])! / 16
//        
//        
//        bind_shape = Matrix.parseMatrix(bind_shape_string)
//        bind_shape!.printOut()
//        
//        for i in 0..<groupVertices.count {
//            groupVertices[i].position = bind_shape! * groupVertices[i].position
//        }
//        
//        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
//        var scanner = NSScanner(string: inv_bind_matrix_string)
//        scanner.charactersToBeSkipped = skipSet
//        
//        for _ in 0..<inv_bind_count {
//            let matrix = Matrix.parseMatrix(scanner)
//            inv_bind_matrices.append(matrix)
//        }
//        
//        scanner = NSScanner(string: weights_string)
//        scanner.charactersToBeSkipped = skipSet
//        
//        var weights = [Float]()
//        while !scanner.atEnd {
//            var w : Float = 0
//            scanner.scanFloat(&w)
//            weights.append(w)
//        }
//        
//        let joints = joints_string.componentsSeparatedByString(" ")
//        skeleton_parts = joints
//        
//        let index_array = weight_indicies_string.componentsSeparatedByString("||")
//        let index_count = Int(index_array[0])!
//        let vcount_arr = index_array[1].componentsSeparatedByString(" ")
//        let indicies = index_array[2].componentsSeparatedByString(" ")
//        
//        for i in 0..<index_count where Int(vcount_arr[i]) > 0 {
////            let vcount = Int(vcount_arr[i])!
//            
////            for v in 0..<vcount {
//                //WARNING, more than one v vount, make explode
//                let joint_i = Int(indicies[2*i])!
//                let weigth_i = Int(indicies[2*i + 1])!
//                print("Join i: \(joint_i), weight_i: \(weigth_i)")
//                var vert = groupVertices[i]
//                vert.bone1 = BoneType(joint_i)
//                vert.bone2 = BoneType(joint_i)
//                vert.weight1 = weights[weigth_i]
//                vert.weight2 = weights[weigth_i]
//                
//                groupVertices[i] = vert
////            }
//        }
//        
//        
//    }
//    
//    func parseSkeleton(structure : [[[String:String]]]){
//        guard skeleton_parts != nil else {
//            return
//        }
//        var parents = [String : Joint]()
//        skeleton = [Joint?](count: skeleton_parts!.count, repeatedValue: nil)
//        var root : Joint?
//        
//        for a in structure {
//            for d in a {
//                
//                let name = d["name"]!
//                print("parse skeleton: \(name)")
//                let matrix = d["transform"]!
//                let parent = d["parent"]!
//                var joint : Joint?
//                if parent.characters.count > 0 {
//                    joint = Joint(name: name, parent: parents[parent])
//                } else{
//                    joint = Joint(name: name, parent: nil)
//                }
//                joint?.transform = Matrix.parseMatrix(matrix)
//                parents[name] = joint!
//                let index = skeleton_parts?.indexOf(name)
//                if index != nil {
//                    skeleton![index!] = joint!
//                } else if root == nil && parent.characters.count == 0{
//                    root = joint!
//                } else{
//                    print("ERROR, multiple roots?")
//                }
//            }
//        }
//
//        updateMatricesForChildren(root!)
//        
//      
//        for i in 0..<skeleton!.count where skeleton![i] != nil{
//            let j = skeleton![i]!
//            j.matrix = (inv_bind_matrices[i] * j.transform)//.transpose
//            updateSkeleton(j, i: i)
//        }
//        
//        
//    }
//    
//    func updateMatricesForChildren(parent : Joint){
//        for j in skeleton! where j != nil && j!.parent! === parent{
//            print("Updating matrix for \(j!.name) from \(parent.name)")
//            
//            j!.transform = parent.transform * j!.transform
//            
//            updateSkeleton(j!)
//            updateMatricesForChildren(j!)
//        }
//    }
//    
//    func updateSkeleton(joint : Joint){
//        let i = skeleton!.indexOf({ (test_j) -> Bool in
//            return joint === test_j
//        })
//        if i != nil {
//            updateSkeleton(joint, i: i!)
//        } else{
//            print("Couldn't update skeleton for \(joint.name), it isn't in the skeleton")
//        }
//    }
//    
//    func updateSkeleton(joint : Joint, i : Int){
//        skeleton?.removeAtIndex(i)
//        skeleton?.insert(joint, atIndex: i)
//    }
//    
//    func parseAnimations(animations_unparsed : [[String : String]]) {
//        
//        animations = [JointAnimation?](count: skeleton_parts!.count, repeatedValue: nil)
//        
//        for ani in animations_unparsed {
//            let joint_name = ani["joint"]!
//            let times_string = ani["times"]!
//            let transform_string = ani["values"]!
//            
//            var transforms = [float4x4]()
//            var scanner = NSScanner(string: transform_string)
//            scanner.charactersToBeSkipped = NSCharacterSet.whitespaceAndNewlineCharacterSet()
//            
//            while !scanner.atEnd {
//                let mat = Matrix.parseMatrix(scanner)
//
//                transforms.append(mat)
//            }
//            
//            var times = [Float]()
//            scanner = NSScanner(string: times_string)
//            scanner.charactersToBeSkipped = NSCharacterSet.whitespaceAndNewlineCharacterSet()
//            while !scanner.atEnd {
//                var time : Float = 0
//                scanner.scanFloat(&time)
//
//                times.append(time)
//            }
//            
//            let a = JointAnimation(joint_name: joint_name, times: times, transforms: transforms)
//            a.printOut()
//            
//            
//            let index = skeleton_parts?.indexOf(joint_name)
//            animations![index!] = a
//            
//////            print("Parsed animation for joint \(joint_name)")
////            for s in skeleton! where s != nil && s!.name == joint_name{
////                let i = skeleton!.indexOf({ (e) -> Bool in return s === e })!
////                s!.matrix = (inv_bind_matrices[i] * transforms[0]).transpose
////                updateSkeleton(s!)
////            }
//        }
//        
//        animations![0]!.transforms[1] = animations![1]!.transforms[1] * animations![0]!.transforms[1]
//        animations![0]!.transforms[0] = animations![1]!.transforms[0] * animations![0]!.transforms[0]
//        setAnimation(0)
//    }
//    
//    
//    func setAnimation(index : Int){
//        for s in skeleton! where s != nil{
//            let i = skeleton!.indexOf({ (e) -> Bool in return s === e })!
//            s!.matrix = (inv_bind_matrices[i] * animations![i]!.transforms[index])//.transpose
//            updateSkeleton(s!)
//        }
//    }
    

    
    
    
}