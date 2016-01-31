//
//  Geometry.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-04.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import UIKit
import simd

struct Box{
    var origin : float3
    var width : Float
    var height : Float
    var depth : Float
    
    func printOut(){
        print("Box:")
        print("Origin: \(origin.x) x \(origin.y) x \(origin.z)")
        print("Dimensions (WxHxD): \(width) x \(height) x \(depth)")
    }
    func rect() -> CGRect {
        return CGRect(x: CGFloat(origin.x), y: CGFloat(origin.y), width: CGFloat(width), height: CGFloat(height))
    }
    
    mutating func rotateX(degrees : Float){
        let p1 = float4(origin.x, origin.y, origin.z, 1.0)
        let p2 = float4(origin.x + width, origin.y + height, origin.z + depth, 1.0)
        
        let rotation_x = Matrix.rotationX(degrees)
        let p1_rot = rotation_x * p1
        let p2_rot = rotation_x * p2
        origin = p1_rot.xyz()
        width = abs(p2_rot.x - p1_rot.x)
        height = abs(p2_rot.y - p1_rot.y)
        depth = abs(p2_rot.z - p1_rot.z)
    }
    mutating func rotateY(degrees : Float){
        let p1 = float4(origin.x, origin.y, origin.z, 1.0)
        let p2 = float4(origin.x + width, origin.y + height, origin.z + depth, 1.0)
        
        let rotation_x = Matrix.rotationY(degrees)
        let p1_rot = rotation_x * p1
        let p2_rot = rotation_x * p2
        origin = p1_rot.xyz()
        width = abs(p2_rot.x - p1_rot.x)
        height = abs(p2_rot.y - p1_rot.y)
        depth = abs(p2_rot.z - p1_rot.z)
    }
}



typealias BoneType = Int16
struct Vertex {
    var position : float4
    var normal : float3
    var texCoords : float2
    var bone1 : BoneType
    var bone2 : BoneType
    var weight1 : Float
    var weight2 : Float
    var bind_pose : float4x4
    
    init(position p : float4, normal n : float3, texCoords t : float2){
        position = p
        normal = n
        texCoords = t
        bone1 = -1
        bone2 = -1
        weight1 = 0
        weight2 = 0
        bind_pose = Matrix.Identity()
    }
    
    init(){
        position = float4(0,0,0,0)
        normal = float3(0,0,0)
        texCoords = float2(0,0)
        bone1 = -1
        bone2 = -1
        weight1 = 0
        weight2 = 0
        bind_pose = Matrix.Identity()
    }
    
    func toData() -> NSData {
        var foo = position
        var foo2 = normal
        var foo3 = texCoords
        var b1 = bone1
        var b2 = bone2
        var w1 = weight1
        var w2 = weight2
        let data = NSMutableData()
        data.appendBytes(&foo, length: sizeof(float4))
        data.appendBytes(&foo2, length: sizeof(float3))
        data.appendBytes(&foo3, length: sizeof(float2))
        data.appendBytes(&b1, length: sizeof(BoneType))
        data.appendBytes(&b2, length: sizeof(BoneType))
        data.appendBytes(&w1, length: sizeof(Float))
        data.appendBytes(&w2, length: sizeof(Float))
        return data
    }
    
    static func offsetForPosition() -> Int{
        return 0
    }
    static func offsetForNormal() -> Int{
        return sizeof(float4)
    }
    static func offsetForTexCoords() -> Int{
        return offsetForNormal() + sizeof(float3)
    }
    static func offsetForBone1() -> Int{
        return offsetForTexCoords() + sizeof(float2)
    }
    static func offsetForBone2() -> Int{
        return offsetForBone1() + sizeof(BoneType)
    }
    static func offsetForWeight1() -> Int{
        return offsetForBone2() + sizeof(BoneType)
    }
    static func offsetForWeight2() -> Int{
        return offsetForWeight1() + sizeof(Float)
    }
}

class HitTest{
    
    static func intersectTop(tl : CGPoint, tr : CGPoint, rect : CGRect) -> CGFloat{
        let ry2 = rect.origin.y + rect.height
        let rx = rect.origin.x
        let rx2 = rect.origin.x + rect.width
        if tl.y < ry2 && tl.y > rect.origin.y{
            if rx > tr.x || rx2 < tl.x {
                return 0.0
            } else {
                return rect.origin.y - tl.y
            }
        }
        return 0.0
    }
    
    
    static func intersectBottom(bl : CGPoint, br : CGPoint, rect : CGRect) -> CGFloat{
        let ry2 = rect.origin.y + rect.height
        let rx = rect.origin.x
        let rx2 = rect.origin.x + rect.width
        if bl.y < ry2 && bl.y > rect.origin.y{
            if rx > br.x || rx2 < bl.x {
                return 0.0
            } else {
                return ry2 - bl.y
            }
        }
        return 0.0
    }
    
    static func intersectRight(r1 : CGPoint, r2 : CGPoint, rect : CGRect) -> CGFloat{
        let ry = rect.origin.y
        let ry2 = rect.origin.y + rect.height
        
        if r1.x > rect.origin.x && r1.x < rect.origin.x + rect.width {
            if ry > r2.y || ry2 < r1.y {
                return 0.0
            } else{
                return r1.x - rect.origin.x
            }
        }
        return 0.0
    }
    
    static func intersectLeft(l1 : CGPoint, l2 : CGPoint, rect : CGRect) -> CGFloat{
        let ry = rect.origin.y
        let ry2 = rect.origin.y + rect.height
        
        if l1.x > rect.origin.x && l1.x < rect.origin.x + rect.width {
            if ry > l2.y || ry2 < l1.y {
                return 0.0
            } else{
                return rect.origin.x + rect.width - l1.x
            }
        }
        return 0.0
    }
    
    static func crossesTop(cur_rect : CGRect, nxt_rect : CGRect, rect : CGRect) -> Bool{
        let rect_bottom =  rect.origin.y
        return cur_rect.origin.y + cur_rect.height <= rect_bottom && nxt_rect.origin.y + nxt_rect.height > rect_bottom
    }
    static func crossesBottom(cur_rect : CGRect, nxt_rect : CGRect, rect : CGRect) -> Bool{
        let rect_top =  rect.origin.y + rect.height
        return cur_rect.origin.y >= rect_top && nxt_rect.origin.y < rect_top
    }
    static func crossesRight(cur_rect : CGRect, nxt_rect : CGRect, rect : CGRect) -> Bool{
        let rect_left = rect.origin.x
        return cur_rect.origin.x + cur_rect.width <= rect_left && nxt_rect.origin.x + nxt_rect.width > rect_left
    }
    static func crossesLeft(cur_rect : CGRect, nxt_rect : CGRect, rect : CGRect) -> Bool{
        let rect_right = rect.origin.x + rect.width
        return cur_rect.origin.x >= rect_right && nxt_rect.origin.x < rect_right
    }
}


