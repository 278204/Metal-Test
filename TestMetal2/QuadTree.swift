//
//  QuadTree.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import simd

class QuadTree{
    private let MAX_OBJECTS = 4
    private let MAX_LEVELS = 5
    
    private let level : Int
    private var statics = [Object]()
//    private var dynamics = [Object]()
    private var nodes : [QuadTree?]
    
    let bounds : AABB
    var uniformBuffer : MTLBuffer?
    
    init(level l : Int, bounds b : float4){
        level = l
        bounds = AABB(rect: b)
        nodes = [QuadTree?](count: 4, repeatedValue: nil)
    }
    
    func clear(){
        statics.removeAll()
//        dynamics.removeAll()
        for i in 0..<nodes.count {
            nodes[i]?.clear()
            nodes[i] = nil
        }
    }
    
    func clearModels(){
//        dynamics.removeAll()
        for i in 0..<nodes.count {
            nodes[i]?.clearModels()
        }
    }
    private func split(){
        
        let subWidth = bounds.width / 2
        let subHeight = bounds.height / 2
        
        let x = bounds.origin.x
        let y = bounds.origin.y
        
        nodes[0] = QuadTree(level: level+1, bounds: float4(x + subWidth, y + subHeight, subWidth, subHeight))
        
        nodes[1] = QuadTree(level: level+1, bounds: float4(x, y + subHeight, subWidth, subHeight))
        
        nodes[2] = QuadTree(level: level+1, bounds: float4(x, y, subWidth, subHeight))
        
        nodes[3] = QuadTree(level: level+1, bounds: float4(x + subWidth, y, subWidth, subHeight))
    }
    
    private func getIndex(rect : AABB) -> [Int]{
        
        
        let verticalMidPoint = bounds.origin.x + (bounds.width / 2)
        let horizontalMidPoint = bounds.origin.y + (bounds.height / 2)
        
        var topQuad = rect.y >= horizontalMidPoint
        var bottomQuad = (rect.max.y < horizontalMidPoint)
        
        let topAndBottom = rect.max.y >= horizontalMidPoint && rect.y <= horizontalMidPoint
        
        if topAndBottom {
            topQuad = false
            bottomQuad = false
        }
        
        if rect.x <= verticalMidPoint && rect.max.x >= verticalMidPoint {
            //Left and Right
            if topQuad {
                return [0,1]
            } else if bottomQuad {
                return [2,3]
            } else if topAndBottom {
                return [0,1,2,3]
            }
            
        } else if rect.x >= verticalMidPoint {
            //Right
            if topQuad {
                 return [0]
            } else if bottomQuad {
                 return [3]
            } else if topAndBottom {
                 return [0,3]
            }
        } else if rect.max.x < verticalMidPoint {
            //Left
            if topQuad {
                 return [1]
            } else if bottomQuad {
                 return [2]
            } else if topAndBottom {
                 return [1,2]
            }
        }
        return [-1]
    }
    
    
    func insert(obj : Object){
//        if bounds.intersects(obj.rect) {
            if nodes[0] == nil {
                
                statics.append(obj)
                
                if statics.count > MAX_OBJECTS && level < MAX_LEVELS {
                    split()
                    for i in 0..<statics.count {
                        let o = statics[i]
                        let index_list  = getIndex(o.rect)
                        for index in index_list {
                            if index != -1 {
                                nodes[index]!.insert(o)
                            }
                        }
                    }
                    statics.removeAll()
                }
            } else {
                let index_list = getIndex(obj.rect)
                for index in index_list {
                    if index != -1 {
                        nodes[index]!.insert(obj)
                    }
                }
            }
//        }
    }

    
    func getNodes()->[QuadTree]{
        
        if nodes[0] == nil {
            return [self]
        }
        
        var list = [QuadTree]()
        for n in nodes {
            let l = n!.getNodes()
            list.appendContentsOf(l)
        }
        list.append(self)
        return list
    }
    
    func retrieveList(o : AABB) -> [Object] {

//        if o is Model {
//            let m = o as! Model
//            let origin = float2(min(m.current_rect.x, m.rect.x), min(m.current_rect.y, m.rect.y))
//            rect = AABB(origin: origin, size: m.current_rect.get_size() + m.rect.get_size())
//        }
        var list = [Object]()
        if nodes[0] != nil {
            let index_list = getIndex(o)
            for index in index_list {
                if index != -1 {
                    let l = nodes[index]!.retrieveList(o)
                    list.appendContentsOf(l)
                }
            }
        } else {
            return statics
        }
        return list
    }
    
    func printOut(){
        print("Level \(level) \(bounds)")
        for n in nodes {
            n?.printOut()
        }
    }
}