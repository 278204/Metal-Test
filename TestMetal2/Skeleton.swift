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
    var temp : float4x4
    let parent : Joint?
    
    init(name n : String, parent p : Joint?, inverse_bind_pose inv_b_p : float4x4){
        name = n
        parent = p
        matrix = Matrix.Identity()
        transform = Matrix.Identity()
        inv_bind_pose = inv_b_p
        temp = Matrix.Identity()
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
    var translates : [float4]
    init(joint_name jn : String, times t : [Float], transforms tfs: [float4x4]){
        joint_name = jn
        times = t
        transforms = tfs
        quaternions = [float4](count: tfs.count, repeatedValue: float4())
        translates = [float4](count: tfs.count, repeatedValue: float4())
    }
    
    func printOut(){
        print("Animation: \(joint_name)")
    }
    
    func convertTransformToQuaternion(){

        for i in 0..<transforms.count {
            quaternions[i] = QuatTrans.convertMatrixToQuaternion(transforms[i])
            translates[i] = QuatTrans.convertMatrixToTranslation(transforms[i])
//            quaternions[i].translate = QuatTrans.convertMatrixToTranslation(transforms[i])
        }
    }
}


protocol SkeletonDelegate {
    func skeletonDidChangeAnimation()
}

class Skeleton{
    var skeleton_parts : [String : Int]
    var joints : [Joint?]
    var animations : [JointAnimation?]
    var delegate : SkeletonDelegate?
    var root_joint : Joint?
    var parser : SkeletonParser?
    
    init () {
        skeleton_parts = [String : Int]()
        animations = [JointAnimation?](count: 0, repeatedValue: nil)
        joints = [Joint?](count: 0, repeatedValue: nil)
    }
    
    func parse(dict : [String : AnyObject], inout vertices : [Vertex]){
        parser = SkeletonParser(skeleton: self)
        
        if dict["skin"] == nil {
            return
        }
        
        let i_b_p = SkeletonParser.parseSkin(dict["skin"] as! [String : String], vertices: &vertices, skeleton_parts: &skeleton_parts)
        parser!.parseSkeleton(dict["skeleton"] as! [[[String : String]]], inv_bind_matrices: i_b_p)
        parser!.parseAnimations(dict["animations"] as! [[String : String]])
//        parser = nil
    }
    
    func updateSkeleton(joint : Joint){
        let i = skeleton_parts[joint.name]
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
    
    func updateSkeleton(inout joints : [Joint?], joint : Joint){
        let i = skeleton_parts[joint.name]
        if i != nil {
            updateSkeleton(joint, i: i!)
        } else{
            print("Couldn't update skeleton for \(joint.name), it isn't in the skeleton")
        }
    }
    

    
    var currentTime : Float = 0
    
    func runAnimation(dt : Float){

        guard animations.count > 0 else{
            return
        }
        currentTime += dt
        
        if animations.first!!.times.last < currentTime {
            currentTime = animations.first!!.times.first!
        }
        
        var current_index = 0
        var next_index = 1
        
        for i in 0..<animations.first!!.times.count-1 where animations.first!!.times[i] < currentTime && animations.first!!.times[i+1] >= currentTime{
            current_index = i
            next_index = i+1
            break
        }
        
        print("Animation \(currentTime) \(current_index) \(next_index)")
        
        
        for j in 0..<animations.count {
            let ani = animations[j]!

            
            let t = (currentTime - animations.first!!.times[current_index]) / (animations.first!!.times[next_index] - animations.first!!.times[current_index])
            
            
            let s = joints[j]!
            
            let quat1 = ani.quaternions[current_index]
            let quat2 = ani.quaternions[next_index]
            
            let trans1 = ani.translates[current_index]
            let trans2 = ani.translates[next_index]
            
            let interpolated_quart = Quaternion.slerp(t, q1: quat1, q2: quat2)
            let interpolated_trans = t * trans2 + (1 - t) * trans1
            let q_t = QuatTrans()
            q_t.quaternion = interpolated_quart
            q_t.translate = interpolated_trans
            
            //WARNING: assumes root to leaf order in joints
            if s.name == "Torso" {
                print("T \(t)")
                if fabs(t) > 1 || t < 0{
                    print("WARNING, t is \(t)")
                }
                print("Quat \(s.inv_bind_pose * quat1)")
                print("Trans \(q_t.translate)")
                q_t.convertToMatrix().printOut()
            }
            
            s.temp = s.parent!.temp * q_t.convertToMatrix()
            s.matrix = (s.temp * s.inv_bind_pose)
            updateSkeleton(s)
        
        }
     
        self.delegate?.skeletonDidChangeAnimation()
        
    }
    
    func setAnimation(index : Int){
        for j in 0..<animations.count {
            let ani = animations[j]!
            let s = joints[j]!
            
            let quat1 = ani.quaternions[index]
            let trans1 = ani.translates[index]
            
            let q_t = QuatTrans()
            q_t.quaternion = quat1
            q_t.translate = trans1
        
            //WARNING: assumes root to leaf order in joints
            s.temp = s.parent!.temp * q_t.convertToMatrix()
            s.matrix = (s.temp * s.inv_bind_pose)
            updateSkeleton(s)
            
        }
        
        self.delegate?.skeletonDidChangeAnimation()
    }
    
    func setAnimation(t : Float, currentIndex : Int, nextIndex : Int){
        print("Set new skeleton frame \(t)")
        for i in 0..<joints.count where joints[i] != nil{
            let s = joints[i]!
            print("Upate \(s.name)")
            let quat1 = animations[i]!.quaternions[currentIndex]
            let quat2 = animations[i]!.quaternions[nextIndex]
            
            let trans1 = animations[i]!.translates[0]
            
            let interpolated_quart = Quaternion.slerp(t, q1: quat1, q2: quat2)
            let interpolated_trans = trans1
            let q_t = QuatTrans()
            q_t.quaternion = interpolated_quart
            q_t.translate = interpolated_trans
            
            s.matrix = (s.inv_bind_pose * q_t.convertToMatrix())// Quaternion.convertToMatrix(interpolated_quart))
            updateSkeleton(s)
        }
        
        self.delegate?.skeletonDidChangeAnimation()
    }
    
    
}