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
    var last_animation : float4x4
    let parent : Joint?
    
    init(name n : String, parent p : Joint?, inverse_bind_pose inv_b_p : float4x4){
        name = n
        parent = p
        matrix = Matrix.Identity()
        transform = Matrix.Identity()
        last_animation = Matrix.Identity()
        inv_bind_pose = inv_b_p
        temp = Matrix.Identity()
    }
    
    func isRoot() -> Bool{
        return parent == nil
    }
    func printOut(){
        let p = isRoot() ? "root" : "parent= \(parent!.name)"
        print("\(name): \(p)")
    }
}


protocol SkeletonDelegate {
    func skeletonDidChangeAnimation(skeleton : Skeleton)
}

class Skeleton{
    var skeleton_parts : [String : Int]
    var joints : [Joint?]
    
    var delegate : SkeletonDelegate?
    var root_joint : Joint?
    var parser : SkeletonParser?
    let animationHandler = AnimationsHandler()
    
    init () {
        skeleton_parts = [String : Int]()
        joints = [Joint?](count: 0, repeatedValue: nil)
    }
    
    func parse(dict : [String : AnyObject], inout vertices : [Vertex]){
        parser = SkeletonParser(skeleton: self)
        
        if dict["skin"] == nil {
            return
        }
        
        parser!.parseSkeleton(dict["skeleton"] as! [[[String : String]]])
        parser!.parseSkin(dict["skin"] as! [String : String], vertices: &vertices)
        parser!.parseAnimations(dict["animations"] as! [[String : String]], animation_name: "run")
       
        animationHandler.type.current = AnimationType.Running
        animationHandler.reset()
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
    
    func changeAnimation(nxt : AnimationType) {
        guard animationHandler.animationsForType.count > 0 else {
            return
        }
        animationHandler.changeAnimation(nxt)
    }

    func runAnimation(dt : Float){
        guard animationHandler.animationsForType.count > 0 else {
            return
        }
        animationHandler.update(dt)
    
        let t : Float = animationHandler.getT()
    
        for j in 0..<animationHandler.frames.current.joints.count {
            let s = joints[j]!
    
            s.temp = s.parent!.temp * animationHandler.getInterpolatedMatrix(t, jointIndex: j)
            s.matrix = (s.temp * s.inv_bind_pose)
            
            updateSkeleton(s, i: j)
            
        }
        self.delegate?.skeletonDidChangeAnimation(self)
    }
    

    func getSkeletonData() -> NSData{
        let skeleton_matrices = NSMutableData()
        
        if joints.count == 0 {
            var mat = Matrix.Identity()
            skeleton_matrices.appendBytes(&mat, length: sizeof(float4x4))
        } else {
            for s in joints where s != nil{
                var mat = s!.matrix
                skeleton_matrices.appendBytes(&mat, length: sizeof(float4x4))
            }
        }
        
        return skeleton_matrices
    }
    
    
}