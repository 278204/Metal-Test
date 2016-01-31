//
//  SkeletonAnimation.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-26.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class JointTransform {
    let quaternion : float4
    let translate : float4
    
    init(transform tfs : float4x4){
        quaternion = QuatTrans.convertMatrixToQuaternion(tfs)
        translate = QuatTrans.convertMatrixToTranslation(tfs)
    }
    
    init(quaternion qt  :float4, translate ts : float4){
        quaternion = qt
        translate = ts
    }
}

class FrameAnimation {
    var frames = [Frame]()
    
    func append(frame : Frame){
        frames.append(frame)
    }
}

class Frame {
    let index : Int
    let time : Float
    var joints = [JointTransform]()
    
    init(){
        time = 0
        index = -1
    }
    init(animation : [JointFrames], index i : Int, time t : Float) {
        time = t
        index = i
        for f in animation {
            joints.append(f.joint_transforms[i])
        }
    }
}

//Should remove
class JointFrames{
    let joint_name : String
    var joint_transforms = [JointTransform]()
    
    init(joint_name jn : String, transforms tfs: [float4x4]){
        joint_name = jn
        for mat in tfs {
            let jt = JointTransform(transform: mat)
            joint_transforms.append(jt)
        }
    }
}

class AnimationsHandler {
    var animationsForType = [AnimationType : FrameAnimation]()
    var last_animations = [JointTransform?]()
    var type : (current : AnimationType, next : AnimationType) = (.Unknown, .Unknown)
    var frames : (current : Frame, next : Frame)
    var current_time : Float
    var loop = true
    
    init(){
        frames = (Frame(), Frame())
        current_time = 0
    }
    
    subscript(index : AnimationType) -> FrameAnimation? {
        get {
            return animationsForType[index]
        } set(newValue) {
            
            let firstValue = animationsForType.count == 0
            animationsForType[index] = newValue
            if firstValue{
                changeAnimation(index)
            }
            last_animations = [JointTransform?](count: animationsForType[index]!.frames.first!.joints.count, repeatedValue: nil)
        }
    }
    
    func isStatic(t : AnimationType)->Bool{
        return self[t]!.frames.count == 1
    }
    func isLast(frame : Frame, forType t : AnimationType)->Bool {
        return frame.index >= self[t]!.frames.count-1
    }
    func isTransitioning() -> Bool {
        return type.current != type.next
    }
    
    func update(dt : Float) {
        
        current_time += dt
        
        if isTransitioning() {
            if current_time > frames.next.time {
                if loop {
                    self.reset()
                } else {
                    return
                }
            }
        } else {
            if current_time > frames.next.time && !isStatic(type.current) {
                if isLast(frames.next, forType: type.current) {
                    if loop {
                        self.reset()
                    } else {
                        return
                    }
                } else {
                    frames.current = frames.next
                    frames.next = self[type.current]!.frames[frames.current.index+1]
                }
            }
        }
    }
    
    func getT()->Float {
        if isTransitioning() {
            let t = (current_time) / frames.next.time
            return t
        }
        let t : Float = frames.current.index == frames.next.index ?
                        1 :
                        (current_time - frames.current.time) /
                        (frames.next.time - frames.current.time)
        return t
    }
    
    
    func getInterpolatedMatrix(t : Float, jointIndex j : Int) -> float4x4{
        
        let q_t = QuatTrans()
        q_t.quaternion = getInterpolatedQuaternion(t, jointIndex: j)
        q_t.translate = getInterpolatedTranslate(t, jointIndex: j)
        
        let jt = JointTransform(quaternion: q_t.quaternion, translate: q_t.translate)
        last_animations[j] = jt
        return q_t.convertToMatrix()
    }
    
    func getInterpolatedQuaternion(t : Float, jointIndex j : Int)->float4{
        var quat1 = frames.current.joints[j].quaternion
        let quat2 = frames.next.joints[j].quaternion
        
        if isTransitioning() && last_animations[j] != nil{
            quat1 = last_animations[j]!.quaternion
        }
        
        return Quaternion.slerp(t, q1: quat1, q2: quat2)
    }
    
    func getInterpolatedTranslate(t : Float, jointIndex j : Int)->float4 {
        var trans1 = frames.current.joints[j].translate
        let trans2 = frames.next.joints[j].translate
        
        if isTransitioning() && last_animations[j] != nil{
            trans1 = last_animations[j]!.translate
        }
        
        return t * trans2 + (1 - t) * trans1
    }
    
    func changeAnimation(nxt : AnimationType) {
        guard self[nxt] != nil else{
            assertionFailure("Tried to change to invalid animation type")
            return
        }
        
        if nxt != type.next {
//            print("new animation type \(nxt)")
            type.next = nxt
            frames.next = self[nxt]!.frames.first!
            current_time = 0
        }
    }
    
    func reset(){
        type.current = type.next
        frames.current = self[type.current]!.frames.first!
        frames.next = !isStatic(type.current) ? self[type.current]!.frames[1] : frames.current
        current_time = frames.current.time
    }
}
