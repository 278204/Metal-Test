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
    
    func parseSkin(skin : [String:String], inout vertices : [Vertex]){
    
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
        
        let joint_names = joints_string.componentsSeparatedByString(" ")
        var index_map = [Int : String]()
        for i in 0..<joint_names.count {
            let name = joint_names[i]
            if index_map[i] == nil {
                index_map[i] = name
            }
        }
        
        let skipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        var scanner = NSScanner(string: inv_bind_matrix_string)
        scanner.charactersToBeSkipped = skipSet
        
        for i in 0..<inv_bind_count {
            let matrix = Matrix.parseMatrix(scanner)
            let joints_index = skeleton.skeleton_parts[index_map[i]!]
            if joints_index != nil {
                skeleton.joints[joints_index!]!.inv_bind_pose = matrix
            } else {
                print("Found non deform joint")
            }
        }
        
        scanner = NSScanner(string: weights_string)
        scanner.charactersToBeSkipped = skipSet
        
        var weights = [Float]()
        while !scanner.atEnd {
            var w : Float = 0
            scanner.scanFloat(&w)
            weights.append(w)
        }
        
        print("nr weights \(weights.count)")
        
        let index_array = weight_indicies_string.componentsSeparatedByString("||")
        let index_count = Int(index_array[0])!
        let vcount_arr = index_array[1].componentsSeparatedByString(" ")
        let indicies = index_array[2].componentsSeparatedByString(" ")
        
        var i = 0

        for vert_i in 0..<index_count{
            //WARNING, more than two v vount, make explode
            
            let first_index = 2*i
            let joint_i = Int(indicies[first_index])!
            let weigth_i = Int(indicies[first_index + 1])!
            let vcount = Int(vcount_arr[vert_i])!
            
//            print("Join i: \(joint_i), weight_i: \(weigth_i)")
            var vert = Vertex()
            
            if vertices.count > vert_i {
                vert = vertices[vert_i]
            }
            
            if vcount == 0 {
                print("WARNING, vcount is zero, \(index_map[joint_i]!)")
            }
            if weights[weigth_i] == 0 {
                print("WARNING, weight is zero, \(index_map[joint_i]!)")
            }
            vert.bind_pose = bind_shape
            
            vert.bone1 = BoneType(skeleton.skeleton_parts[index_map[joint_i]!]!)
            vert.weight1 = weights[weigth_i]
            
            
            if vcount == 2 {
                let joint_i2 = Int(indicies[first_index+2])!
                let weigth_i2 = Int(indicies[first_index+3])!

                vert.bone2 = BoneType(skeleton.skeleton_parts[index_map[joint_i2]!]!)
                vert.weight2 = weights[weigth_i2]
                
                if index_map[joint_i2] == "Toe_L" {
                    print("\(index_map[joint_i]) skin \(vert.weight2) \(vcount)")
                }
                if vert.weight2 > vert.weight1 {
                    let bone_temp = vert.bone2
                    let weight_temp = vert.weight2
                    vert.bone2 = vert.bone1
                    vert.weight2 = vert.weight1
                    vert.bone1 = bone_temp
                    vert.weight1 = weight_temp
                }
            } else if vcount > 2 {
                print("ERROR, can't handle vcount higher than 2")
            }
            
            if index_map[joint_i] == "Toe_L" {
                print("Foot skin \(vert.weight1) \(vcount)")
            }
            

            if vertices.count <= vert_i {
                vertices.append(vert)
            } else {
                vertices[vert_i] = vert
            }

            i += vcount
        }
        print("vert count \(vertices.count)")
        
        skeleton.root_joint!.temp = skeleton.root_joint!.transform
        //WARNING: assumes root to leaf order in joints
        for i in 0..<skeleton.joints.count where skeleton.joints[i] != nil{
            let j = skeleton.joints[i]!
            j.temp = j.parent!.temp * j.transform
            
            j.matrix = (j.temp * j.inv_bind_pose)//.transpose
            updateSkeleton(j, i: i)
        }
    }
    
    func parseSkeleton(structure : [[[String:String]]]){
 
        var parents = [String : Joint]()
        skeleton.joints = [Joint]()
//        var root : Joint?
        var index = 0
        for a in structure {
            for d in a {
                let name = d["name"]!
                let matrix = d["transform"]!
                let parent = d["parent"]!
                var joint : Joint?
                
                if name.containsString("_Controller") || name.containsString("_IK") || name.containsString("_pole"){
                    continue
                }
                
                skeleton.skeleton_parts[name] = index
                if parent.characters.count > 0 {
                    joint = Joint(name: name, parent: parents[parent], inverse_bind_pose: Matrix.Identity())
                    skeleton.joints.append(joint!)
                    index += 1
                } else{
                    print("WARNING, cant find bone in skeleton_parts \(name)")
                    joint = Joint(name: name, parent: nil, inverse_bind_pose: Matrix.Identity())
//                    root = joint!
                    skeleton.root_joint = joint!
                }

                joint?.transform = Matrix.parseMatrix(matrix)
                parents[name] = joint!
            }
        }
    }
    
    func updateSkeleton(joint : Joint){
        
        let i = skeleton.skeleton_parts[joint.name]
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
    
    func parseAnimations(animations_unparsed : [[String : String]], animation_name : String) {
        
        var frames = [JointFrames?](count: skeleton.joints.count, repeatedValue: nil)
        var frame_times = [Float]()
        for ani in animations_unparsed {
            let joint_name = ani["joint"]!
            
            if skeleton.skeleton_parts[joint_name] == nil {
                print("WARNING, can't find \(joint_name) in skeleton_parts, continuing")
                continue
            }
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
            
            if(frame_times.count == 0){
                frame_times = times
            } else if frame_times.count != times.count {
                print("ERROR, all joints doesn't same amount of times, \(joint_name) has \(times.count)")
                assertionFailure()
            }
            
            
            let a = JointFrames(joint_name: joint_name, transforms: transforms)
            
            let index = skeleton.skeleton_parts[joint_name]
            
            if index != nil && index! < frames.count {
                frames[index!] = a
            } else{
                print("Found animation for non deform joint \(joint_name)")
            }
        }
        
        var frames_final = [JointFrames]()
        for f in frames where f != nil {
            frames_final.append(f!)
        }
        
        let frame_anim = FrameAnimation()
        for i in 0..<frame_times.count {
            let frame = Frame(animation: frames_final, index: i, time: frame_times[i])
            frame_anim.append(frame)
        }
        
        let state = AnimationType.stringToState(animation_name)
        if state != .Unknown {
            skeleton.animationHandler[state] = frame_anim
        } else {
            assertionFailure("ERROR, cant find animation state for \(animation_name)")
        }
    }
}