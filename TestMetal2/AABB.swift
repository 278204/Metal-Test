//
//  AABB.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-27.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class AABB : CustomStringConvertible {
    var origin = float2(0,0)
    var height : Float = 0.0
    var width : Float = 0.0
    
    var x : Float { get { return origin.x }}
    var y : Float { get { return origin.y }}
    var max : float2 { get { return get_max() }}
    var mid : float2 { get { return float2(x + width/2, y + height/2) }}
    var description : String {
        return "x:\(origin.x) y:\(origin.y) w:\(width) h:\(height)"
    }
    
    init(){
        
    }
    init(rect : float4){
        origin.x = rect.x
        origin.y = rect.y
        width = rect.z
        height = rect.w
    }
    init(origin o : float2, size : float2){
        origin = o
        width = size.x
        height = size.y
    }
    init(rect : CGRect){
        origin = float2(Float(rect.origin.x), Float(rect.origin.y))
        width = Float(rect.width)
        height = Float(rect.height)
    }
    func get_min() -> float2{
        return origin
    }
    func get_max() -> float2{
        return origin + get_size()
    }
    func get_size() -> float2{
        return float2(width, height)
    }
    
    func contains(other : AABB) -> Bool {
        return other.origin.x >= origin.x && other.origin.y >= origin.y && other.max.x <= max.x && other.max.y <= max.y
    }
    
    func intersects(other : AABB) -> Bool{
        let md = minkowskiDifference(other)
        return md.isAtOrigo()
    }
    
    func isAtOrigo() -> Bool {
        let maximum = get_max()
        return origin.x <= 0 && maximum.x >= 0 &&
            origin.y <= 0 && maximum.y >= 0
    }
    
    func minkowskiDifference(other : AABB) -> AABB{
        let top_left = origin - other.get_max()
        let full_size = get_size() + other.get_size()
        return AABB(origin: top_left, size: full_size)
    }
    
    func closestPointOnBoundsToOrigin() -> (penetration_vector : float2, side : Direction){
        
        let point = float2(0,0)
        let max = get_max()
        var direction = Direction.Left
        var min_dist : Float = abs(point.x - origin.x)
        var boundsPoints = float2(origin.x, point.y)
        
        if abs(max.x - point.x) < min_dist { // Right
            direction = .Right
            min_dist = abs(max.x - point.x)
            boundsPoints = float2(max.x, point.y)
        }
        
        if abs(max.y - point.y) < min_dist { // Top
            direction = .Top
            min_dist = abs(max.y - point.y)
            boundsPoints = float2(point.x, max.y)
        }
        
        if abs(origin.y - point.y) < min_dist { // Bottom
            direction = .Bottom
            min_dist = abs(origin.y - point.y)
            boundsPoints = float2(point.x, origin.y)
        }
        
        return (boundsPoints, direction)
    }
    

    
    func getRayIntersectionFraction(originA : float2, directionA : float2) -> (h : Float, side : Direction) {
        let endA = originA + directionA
        let max = self.get_max()
        let min = self.origin
        
        var direction = Direction.Left
        var minT = getRayIntersectionFractionOfFirstRay(originA, endA: endA, originB: min, endB: float2(min.x, max.y))
        
        var x = getRayIntersectionFractionOfFirstRay(originA, endA: endA, originB: float2(min.x, max.y), endB: max)
        if x < minT {
            direction = .Top
            minT = x
        }
        x = getRayIntersectionFractionOfFirstRay(originA, endA: endA, originB: max, endB: float2(max.x, min.y))
        if x < minT {
            direction = .Right
            minT = x
        }
        x = getRayIntersectionFractionOfFirstRay(originA, endA: endA, originB: float2(max.x, min.y), endB: min)
        if x < minT {
            direction = .Bottom
            minT = x
        }
        
        return (minT, direction)
    }
    
    private func getRayIntersectionFractionOfFirstRay(originA : float2, endA : float2, originB : float2, endB : float2) -> Float{
        let r = endA - originA
        let s = endB - originB
        
        let numerator = (originB - originA).cross(r)
        let denominator = r.cross(s)
        
        //OPTIMIZE, unecesarry?
        if numerator == 0 && denominator == 0 {
            return Float.infinity
        }
        if denominator == 0 {
            return Float.infinity
        }
        
        let u = numerator / denominator
        let t = ((originB - originA).cross(s))/denominator
        
        if  t >= 0 && t <= 1 &&
            u >= 0 && u <= 1 {
            return t
        }
        return Float.infinity
    }
}