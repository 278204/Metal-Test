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
    var inv_bind_pose : float4x4
    
    
    let parent : Joint?
    
    init(name n : String, parent p : Joint?, inverse_bind_pose inv_b_p : float4x4){
        name = n
        parent = p
        matrix = Matrix.Identity()
        transform = Matrix.Identity()
        inv_bind_pose = inv_b_p
        
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
    var quaternions : [float4]
    
    init(joint_name jn : String, times t : [Float], transforms tfs: [float4x4]){
        joint_name = jn
        times = t
        transforms = tfs
        quaternions = [float4](count: tfs.count, repeatedValue: float4())
    }
    
    func printOut(){
        print("Animation: \(joint_name)")
    }
    
    func convertTransformToQuaternion(){
        for i in 0..<transforms.count {
            quaternions[i] = Quaternion.convertMatrix(transforms[i])
        }
    }
}


protocol SkeletonDelegate {
    func skeletonDidChangeAnimation()
}
class Skeleton{
    var skeleton_parts : [String : Int] = [String : Int]()
    var joints : [Joint?]
    var animations : [JointAnimation?]
    var delegate : SkeletonDelegate?
    var root_joint : Joint?
    
    init () {
        animations = [JointAnimation?](count: 0, repeatedValue: nil)
        joints = [Joint?](count: 0, repeatedValue: nil)
    }
    
    
    func parseSkin(skin : [String:String], inout vertices : [Vertex]) -> [float4x4]{
        
        let name = skin["name"]!
        
        let weights_string = skin["weights"]!
        let bind_shape_string = skin["bind_shape"]!
        let joints_string = skin["joints"]!
        let weight_indicies_string = skin["weights_indicies"]!
        var inv_bind_matrix_string = skin["inv_bind_matrix"]!
        
        let inv_bind_array = inv_bind_matrix_string.componentsSeparatedByString("||");
        inv_bind_matrix_string = inv_bind_array[1]
        let inv_bind_count = Int(inv_bind_array[0])! / 16
        
        
        let bind_shape = Matrix.parseMatrix(bind_shape_string)
        
        for i in 0..<vertices.count {
            vertices[i].position = bind_shape * vertices[i].position
        }
        
        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        var scanner = NSScanner(string: inv_bind_matrix_string)
        scanner.charactersToBeSkipped = skipSet
        var inv_bind_matrices = [float4x4]()
        
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
        
        let joint_names = joints_string.componentsSeparatedByString(" ")
        for i in 0..<joint_names.count {
            let name = joint_names[i]
            skeleton_parts[name] = i
        }
        
        let index_array = weight_indicies_string.componentsSeparatedByString("||")
        let index_count = Int(index_array[0])!
        let vcount_arr = index_array[1].componentsSeparatedByString(" ")
        let indicies = index_array[2].componentsSeparatedByString(" ")
        
        for i in 0..<index_count where Int(vcount_arr[i]) > 0 {
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
        }
        return inv_bind_matrices
        
    }
    
    func parseSkeleton(structure : [[[String:String]]], inv_bind_matrices : [float4x4]){

        var parents = [String : Joint]()
        joints = [Joint?](count: skeleton_parts.values.count, repeatedValue: nil)
        var root : Joint?
        
        for a in structure {
            for d in a {
                
                let name = d["name"]!
                print("parse skeleton: \(name)")
                let matrix = d["transform"]!
                let parent = d["parent"]!
                var joint : Joint?
                let index = skeleton_parts[name]
                
                if parent.characters.count > 0 {
                    joint = Joint(name: name, parent: parents[parent], inverse_bind_pose: inv_bind_matrices[index!])
                } else{
                    joint = Joint(name: name, parent: nil, inverse_bind_pose: Matrix.Identity())
                }
                joint?.transform = Matrix.parseMatrix(matrix)
                parents[name] = joint!
                
                if index != nil {
                    joints[index!] = joint!
                } else if root == nil && parent.characters.count == 0{
                    root = joint!
                    root_joint = joint!
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
        
        animations = [JointAnimation?](count: joints.count, repeatedValue: nil)

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
            
            
            let index = skeleton_parts[joint_name]
            animations[index!] = a
            
        }
    
        
        updateTransformsToAbsolute(root_joint!, ani: &animations)
        
        for j_a in animations {
            j_a?.convertTransformToQuaternion()
        }
    }
    
    func updateTransformsToAbsolute(parent : Joint, inout ani : [JointAnimation?]){
        //OPTIMAZE?
        for j in ani where joints[skeleton_parts[j!.joint_name]!]!.parent === parent{
            
            for i in 0..<j!.transforms.count {
                j!.transforms[i] = parent.transform * j!.transforms[i]
            }
            updateTransformsToAbsolute(joints[skeleton_parts[j!.joint_name]!]!, ani: &ani)
        }
    }
    
    
    func setAnimation(index : Int){
        print("Set new skeleton frame \(index)")
        for s in joints where s != nil{
            let i = joints.indexOf({ (e) -> Bool in return s === e })!
            s!.matrix = (s!.inv_bind_pose * animations[i]!.transforms[index])//.transpose
            updateSkeleton(s!)
        }
    
        self.delegate?.skeletonDidChangeAnimation()
    }
    
    func setAnimation(t : Float){
        print("Set new skeleton frame \(t)")
        for i in 0..<joints.count where joints[i] != nil{
            let s = joints[i]!
            
            let quat1 = animations[i]!.quaternions[0]
            let quat2 = animations[i]!.quaternions[1]
            
            let quart = Quaternion.slerp(t, q1: quat1, q2: quat2)
            
            s.matrix = (s.inv_bind_pose * Quaternion.convertToMatrix(quart))//.transpose
            updateSkeleton(s)
        }
        
        self.delegate?.skeletonDidChangeAnimation()
    }
    
    
}