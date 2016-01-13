//
//  SkeletonPraser.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-09.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class SkeletonParser{
    
    //OPTIMIZE, remove dependency
    var skeleton : Skeleton
    
    init(skeleton sk : Skeleton){
        skeleton = sk
    }
    
    class func parseSkin(skin : [String:String], inout vertices : [Vertex], inout skeleton_parts : [String:Int]) -> [float4x4]{
        
//        let name = skin["name"]!
        
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
            if skeleton_parts[name] == nil {
                skeleton_parts[name] = i
            }
        }
        
        let index_array = weight_indicies_string.componentsSeparatedByString("||")
        let index_count = Int(index_array[0])!
        let vcount_arr = index_array[1].componentsSeparatedByString(" ")
        let indicies = index_array[2].componentsSeparatedByString(" ")
        
        var i = 0
        var vert_i = 0
        while vert_i < index_count{
            //WARNING, more than one v vount, make explode
            
            let first_index = 2*i
            let joint_i = Int(indicies[first_index])!
            let weigth_i = Int(indicies[first_index + 1])!
            let vcount = Int(vcount_arr[vert_i])!
            
            print("Join i: \(joint_i), weight_i: \(weigth_i)")
            var vert = Vertex()
            
            if vertices.count > vert_i {
                vert = vertices[vert_i]
            }
            
            vert.bone1 = BoneType(joint_i)
            vert.weight1 = weights[weigth_i]
            
            if vcount == 2 {
                let joint_i2 = Int(indicies[first_index+2])!
                let weigth_i2 = Int(indicies[first_index + 3])!
                vert.bone2 = BoneType(joint_i2)
                vert.weight2 = weights[weigth_i2]
            }

            if vertices.count <= vert_i {
                vertices.append(vert)
            } else {
                vertices[vert_i] = vert
            }
            
            vert_i += 1
            i += vcount
        }
        return inv_bind_matrices
    }
    
    func parseSkeleton(structure : [[[String:String]]], inv_bind_matrices : [float4x4]){
        
        var parents = [String : Joint]()
        skeleton.joints = [Joint?](count: skeleton.skeleton_parts.values.count, repeatedValue: nil)
        var root : Joint?
        
        for a in structure {
            for d in a {
                
                let name = d["name"]!
                print("parse skeleton: \(name)")
                let matrix = d["transform"]!
                let parent = d["parent"]!
                var joint : Joint?
                let index = skeleton.skeleton_parts[name]
                
                if parent.characters.count > 0 && index != nil {
                    joint = Joint(name: name, parent: parents[parent], inverse_bind_pose: inv_bind_matrices[index!])
                } else{
                    joint = Joint(name: name, parent: nil, inverse_bind_pose: Matrix.Identity())
                }
                joint?.transform = Matrix.parseMatrix(matrix)
                parents[name] = joint!
                
                if index != nil {
                    skeleton.joints[index!] = joint!
                } else if root == nil && parent.characters.count == 0{
                    root = joint!
                    skeleton.root_joint = joint!
                } else{
                    print("ERROR, multiple roots? Perhaps non-deforming bone?")
                }
            }
        }
        
//        updateMatricesForChildren(root!)
        skeleton.root_joint!.temp = skeleton.root_joint!.transform
        
        //WARNING: assumes root to leaf order in joints
        for i in 0..<skeleton.joints.count where skeleton.joints[i] != nil{
            let j = skeleton.joints[i]!
            j.temp = j.parent!.temp * j.transform
            
            print("Updating matrix for \(j.name) from \(j.parent!.name) \(j.temp)")
            j.matrix = (j.temp * j.inv_bind_pose)//.transpose
            updateSkeleton(j, i: i)
        }
        
        
    }
    
    func updateMatricesForChildren(parent : Joint){
        for j in skeleton.joints where j != nil && j!.parent! === parent{
            
            
            j!.transform = parent.transform * j!.transform
            
            print("Updating matrix for \(j!.name) from \(parent.name) \(j!.transform)")
            updateSkeleton(j!)
            updateMatricesForChildren(j!)
        }
    }
    
    func updateSkeleton(joint : Joint){
        
        let i = skeleton.skeleton_parts[joint.name]
        //        let i = joints.indexOf({ (test_j) -> Bool in
        //            return joint === test_j
        //        })
        if i != nil {
            updateSkeleton(joint, i: i!)
        } else{
            print("Couldn't update skeleton for \(joint.name), it isn't in the skeleton")
        }
    }
    
    func updateSkeleton(joint : Joint, i : Int){
        skeleton.joints.removeAtIndex(i)
        skeleton.joints.insert(joint, atIndex: i)
    }
    
    func parseAnimations(animations_unparsed : [[String : String]]) {
        
        skeleton.animations = [JointAnimation?](count: skeleton.joints.count, repeatedValue: nil)
        
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
            a.convertTransformToQuaternion()
            a.printOut()
            
            
            let index = skeleton.skeleton_parts[joint_name]
            if index != nil {
                skeleton.animations[index!] = a
            } else{
                print("Found animation for non deform joint \(joint_name)")
//                skeleton.animations.append(a)
            }
            
        }
        
//        updateTransformsToAbsolute(skeleton.root_joint!, ani: &skeleton.animations)
        
//        for j_a in skeleton.animations {
//            j_a?.convertTransformToQuaternion()
//        }
    }
    
//    func updateTransformsToAbsolute(parent : Joint, inout ani : [JointAnimation?]){
//        //OPTIMAZE?
//        for j in ani where skeleton.joints[skeleton.skeleton_parts[j!.joint_name]!]!.parent === parent{
//            
//            for i in 0..<j!.transforms.count {
//                j!.transforms[i] = parent.transform * j!.transforms[i]
//            }
//            updateTransformsToAbsolute(skeleton.joints[skeleton.skeleton_parts[j!.joint_name]!]!, ani: &ani)
//        }
//    }
//    

    
}