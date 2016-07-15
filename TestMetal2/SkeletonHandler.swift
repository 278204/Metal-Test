//
//  SkeletonHandler.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


enum SkeletonClass :Int {
    case Player = 0
    case Ghost
    case None

}
class SkeletonMap{
    static var map = [SkeletonClass : SkeletonHandler]()
    
    
    class func setSkeleton(a : Object, skel : Skeleton) {
//        print("Set skeleton \(a)")
        let skelClass = getSkeletonClass(a)

        let handler = map[skelClass]
        if handler == nil {
            if skelClass == .Player {
                map[skelClass] = PlayerSkeletonHandler(skeleton: skel, test: false)
            } else {
               map[skelClass] = SkeletonHandler(skeleton: skel)
            }

        } else {
//            print("WARNING, tried to set same skeleton multiple times")
        }
    }
    
    class func getHandler(a : Object) -> SkeletonHandler?{
        let skelClass = getSkeletonClass(a)
        return map[skelClass]
    }
    
    class func getSkeletonClass(a : Object) -> SkeletonClass{
        if a is Player {
            return .Player
        } else if a is Ghost {
            return .Ghost
        }
        return .None
    }
}

class PlayerSkeletonHandler : SkeletonHandler{
    var buffer : MTLBuffer?
   
    override init(skeleton skel: Skeleton, test : Bool) {
        super.init(skeleton: skel, test: test)
        skel.animationHandler.canTransition = true
    }
    
    
    override func updateBuffer(dt : Float, ani : AnimationType) {
        skeleton?.changeAnimation(ani)
        skeleton?.runAnimation(dt)
    }
    
    override func getBuffer(ani : AnimationType) -> MTLBuffer {
        return buffer!
    }

    //Gets called after getBuffer
    override func skeletonDidChangeAnimation(skeleton : Skeleton) {
        
        updateBuffer(skeleton.getSkeletonData(), ani: skeleton.animationHandler.type.current)
    }
    
    override func updateBuffer(data : NSData, ani : AnimationType) {

        let skeleton_matrices = data
        if buffer == nil {
            buffer = Graphics.shared.renderer.newBufferWithBytes(skeleton_matrices.bytes, length: skeleton_matrices.length)
        } else {
            memcpy(buffer!.contents(), skeleton_matrices.bytes, skeleton_matrices.length);
        }
    }
}

class SkeletonHandler : SkeletonDelegate {

    let skeleton : Skeleton?
    var bufferMap = [AnimationType : MTLBuffer]()
    var updated = [AnimationType : Bool]()
    

    init(skeleton skel : Skeleton, test : Bool){
        skeleton = skel
        skeleton!.delegate = self
    }
    
    init(skeleton skel : Skeleton){
        skeleton = skel
        skeleton!.delegate = self
        if skel.animationHandler.animationsForType.count > 0 {
            for type in skeleton!.animationHandler.animationsForType.keys {
                updateBuffer(skeleton!.getSkeletonData(), ani: type)
            }
            updateBuffer(skeleton!.getIdentitySkeletonData(), ani: .Unknown)
        } else {
            updateBuffer(skeleton!.getSkeletonData(), ani: .Unknown)
        }
    }
    
    func updateBuffer(dt : Float, ani : AnimationType) {
        if updated[ani] == true {
            return
        }
        skeleton?.changeAnimation(ani)
        skeleton?.runAnimation(dt)
        updated[ani] = true
    }

    func getBuffer(ani : AnimationType) -> MTLBuffer {
        return bufferMap[ani]!
    }
    
    func reset(){
        updated.removeAll()
    }
    
    //Gets called after getBuffer
    func skeletonDidChangeAnimation(skeleton : Skeleton) {

        updateBuffer(skeleton.getSkeletonData(), ani: skeleton.animationHandler.type.current)
    }
    
    func updateBuffer(data : NSData, ani : AnimationType) {
        var buffer = bufferMap[ani]
        let skeleton_matrices = data
        if buffer == nil {
            buffer = Graphics.shared.renderer.newBufferWithBytes(skeleton_matrices.bytes, length: skeleton_matrices.length)
            bufferMap[ani] = buffer
        } else {
            memcpy(buffer!.contents(), skeleton_matrices.bytes, skeleton_matrices.length);
        }
    }
}