//
//  File.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-08.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class Joint {
    let name : String
    var matrix : float4x4
    var transform : float4x4
    let parent : Joint?
    
    init(name n : String, parent p : Joint?){
        name = n
        parent = p
        matrix = Matrix.Identity()
        transform = Matrix.Identity()
    }
    
    func isRoot() -> Bool{
        return parent == nil
    }
    func printOut(){
        let p = parent == nil ? "root" : "parent= \(parent!.name)"
        print("\(name): \(p)")
    }
}

class JointAnimation{
    let joint_name : String
    let times : [Float]
    var transforms : [float4x4]
    
    init(joint_name jn : String, times t : [Float], transforms tfs: [float4x4]){
        joint_name = jn
        times = t
        transforms = tfs
    }
    
    func printOut(){
        print("Animation: \(joint_name)")
    }
}


protocol SkeletonDelegate {
    func skeletonDidChangeAnimation()
}
class Skeleton{
    var skeleton_parts : [String]?
    var joints : [Joint?]
    var inv_bind_matrices = [float4x4]()
    var bind_shape : float4x4 = Matrix.Identity()
    var animations : [JointAnimation?]
    var delegate : SkeletonDelegate?
    
    init () {
        animations = [JointAnimation?](count: 0, repeatedValue: nil)
        joints = [Joint?](count: 0, repeatedValue: nil)
    }
    
    
    func parseSkin(skin : [String:String], inout vertices : [Vertex]){
        
        let name = skin["name"]!
        
        let weights_string = skin["weights"]!
        let bind_shape_string = skin["bind_shape"]!
        let joints_string = skin["joints"]!
        let weight_indicies_string = skin["weights_indicies"]!
        var inv_bind_matrix_string = skin["inv_bind_matrix"]!
        
        let inv_bind_array = inv_bind_matrix_string.componentsSeparatedByString("||");
        inv_bind_matrix_string = inv_bind_array[1]
        let inv_bind_count = Int(inv_bind_array[0])! / 16
        
        
        bind_shape = Matrix.parseMatrix(bind_shape_string)
        bind_shape.printOut()
        
        for i in 0..<vertices.count {
            vertices[i].position = bind_shape * vertices[i].position
        }
        
        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        var scanner = NSScanner(string: inv_bind_matrix_string)
        scanner.charactersToBeSkipped = skipSet
        
        for _ in 0..<inv_bind_count {
            let matrix = Matrix.parseMatrix(scanner)
            inv_bind_matrices.append(matrix)
        }
        
        scanner = NSScanner(string: weights_string)
        scanner.charactersToBeSkipped = skipSet
        
        var weights = [Float]()
        while !scanner.atEnd {
            var w : Float = 0
            scanner.scanFloat(&w)
            weights.append(w)
        }
        
        let joints = joints_string.componentsSeparatedByString(" ")
        skeleton_parts = joints
        
        let index_array = weight_indicies_string.componentsSeparatedByString("||")
        let index_count = Int(index_array[0])!
        let vcount_arr = index_array[1].componentsSeparatedByString(" ")
        let indicies = index_array[2].componentsSeparatedByString(" ")
        
        for i in 0..<index_count where Int(vcount_arr[i]) > 0 {
            //            let vcount = Int(vcount_arr[i])!
            
            //            for v in 0..<vcount {
            //WARNING, more than one v vount, make explode
            let joint_i = Int(indicies[2*i])!
            let weigth_i = Int(indicies[2*i + 1])!
            print("Join i: \(joint_i), weight_i: \(weigth_i)")
            var vert = vertices[i]
            vert.bone1 = BoneType(joint_i)
            vert.bone2 = BoneType(joint_i)
            vert.weight1 = weights[weigth_i]
            vert.weight2 = weights[weigth_i]
            
            vertices[i] = vert
            //            }
        }
        
        
    }
    
    func parseSkeleton(structure : [[[String:String]]]){
        guard skeleton_parts != nil else {
            return
        }
        var parents = [String : Joint]()
        joints = [Joint?](count: skeleton_parts!.count, repeatedValue: nil)
        var root : Joint?
        
        for a in structure {
            for d in a {
                
                let name = d["name"]!
                print("parse skeleton: \(name)")
                let matrix = d["transform"]!
                let parent = d["parent"]!
                var joint : Joint?
                if parent.characters.count > 0 {
                    joint = Joint(name: name, parent: parents[parent])
                } else{
                    joint = Joint(name: name, parent: nil)
                }
                joint?.transform = Matrix.parseMatrix(matrix)
                parents[name] = joint!
                let index = skeleton_parts?.indexOf(name)
                if index != nil {
                    joints[index!] = joint!
                } else if root == nil && parent.characters.count == 0{
                    root = joint!
                } else{
                    print("ERROR, multiple roots?")
                }
            }
        }
        
        updateMatricesForChildren(root!)
        
        
        for i in 0..<joints.count where joints[i] != nil{
            let j = joints[i]!
            j.matrix = (inv_bind_matrices[i] * j.transform)//.transpose
            updateSkeleton(j, i: i)
        }
        
        
    }
    
    func updateMatricesForChildren(parent : Joint){
        for j in joints where j != nil && j!.parent! === parent{
            print("Updating matrix for \(j!.name) from \(parent.name)")
            
            j!.transform = parent.transform * j!.transform
            
            updateSkeleton(j!)
            updateMatricesForChildren(j!)
        }
    }
    
    func updateSkeleton(joint : Joint){
        let i = joints.indexOf({ (test_j) -> Bool in
            return joint === test_j
        })
        if i != nil {
            updateSkeleton(joint, i: i!)
        } else{
            print("Couldn't update skeleton for \(joint.name), it isn't in the skeleton")
        }
    }
    
    func updateSkeleton(joint : Joint, i : Int){
        joints.removeAtIndex(i)
        joints.insert(joint, atIndex: i)
    }
    
    func parseAnimations(animations_unparsed : [[String : String]]) {
        
        animations = [JointAnimation?](count: skeleton_parts!.count, repeatedValue: nil)

        for ani in animations_unparsed {
            let joint_name = ani["joint"]!
            let times_string = ani["times"]!
            let transform_string = ani["values"]!
            
            var transforms = [float4x4]()
            var scanner = NSScanner(string: transform_string)
            scanner.charactersToBeSkipped = NSCharacterSet.whitespaceAndNewlineCharacterSet()
            
            while !scanner.atEnd {
                let mat = Matrix.parseMatrix(scanner)
                
                transforms.append(mat)
            }
            
            var times = [Float]()
            scanner = NSScanner(string: times_string)
            scanner.charactersToBeSkipped = NSCharacterSet.whitespaceAndNewlineCharacterSet()
            while !scanner.atEnd {
                var time : Float = 0
                scanner.scanFloat(&time)
                
                times.append(time)
            }
            
            let a = JointAnimation(joint_name: joint_name, times: times, transforms: transforms)
            a.printOut()
            
            
            let index = skeleton_parts?.indexOf(joint_name)
            animations[index!] = a
            
        }
        
        animations[0]!.transforms[1] = animations[1]!.transforms[1] * animations[0]!.transforms[1]
        animations[0]!.transforms[0] = animations[1]!.transforms[0] * animations[0]!.transforms[0]

    }
    
    
    func setAnimation(index : Int){
        print("Set new skeleton frame \(index)")
        for s in joints where s != nil{
            let i = joints.indexOf({ (e) -> Bool in return s === e })!
            s!.matrix = (inv_bind_matrices[i] * animations[i]!.transforms[index])//.transpose
            updateSkeleton(s!)
        }
        
        self.delegate?.skeletonDidChangeAnimation()
    }
    
    
}