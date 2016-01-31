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
    private let MAX_OBJECTS = 10
    private let MAX_LEVELS = 1000
    
    private let level : Int
    private var objects = [Object]()
    private var models = [Object]()
    private let bounds : AABB
    private var nodes : [QuadTree?]
    
    init(level l : Int, bounds b : float4){
        level = l
        bounds = AABB(rect: b)
        nodes = [QuadTree?](count: 4, repeatedValue: nil)
    }
    
    func clear(){
        objects.removeAll()
        models.removeAll()
        for i in 0..<nodes.count {
            nodes[i]?.clear()
            nodes[i] = nil
        }
    }
    
    func clearModels(){
        models.removeAll()
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
    
    private func getIndex(rect : AABB) -> Int{
        var index = -1
        let verticalMidPoint = bounds.origin.x + (bounds.width / 2)
        let horizontalMidPoint = bounds.origin.y + (bounds.height / 2)
        
        let topQuad = (rect.origin.y >= horizontalMidPoint)
        let bottomQuad = (rect.get_max().y < horizontalMidPoint)
        
        if rect.origin.x < verticalMidPoint && rect.get_max().x < verticalMidPoint  {
            //In left quad
            if topQuad {
                index = 1
            } else if bottomQuad {
                index = 2
            }
        } else if rect.origin.x > verticalMidPoint {
            //In right quad
            if topQuad {
                index = 0
            } else if bottomQuad {
                index = 3
            }
        }
//        print("parent \(bounds)")
//        print("child node \(rect) \(index)")
        
        return index
    }
    
    func insert(obj : Object) {
        if nodes[0] != nil {
            let index = getIndex(obj.rect)
            if index > -1 {
                nodes[index]!.insert(obj)
                return
            }
        }
        
        if obj is Model {
            models.append(obj)
        } else {
            objects.append(obj)
        }
        
        if objects.count + models.count >= MAX_OBJECTS && level < MAX_LEVELS {
            if nodes[0] == nil {
                split()
            }
            var i = 0
            while i < objects.count {
                let o = objects[i]
                let index = getIndex(o.rect)
                if index != -1 {
                    nodes[index]!.insert(objects.removeAtIndex(i))
                } else {
                    i += 1
                }
            }
            i = 0
            while i < models.count {
                let o = models[i]
                let index = getIndex(o.rect)
                if index != -1 {
                    nodes[index]!.insert(models.removeAtIndex(i))
                } else {
                    i += 1
                }
            }
        } else if level >= MAX_LEVELS {
            print("WARNING, hit limit of quadtree levels \(level)")
        }
    }
    
    func retrieveList(o : Object) -> [Object] {
        let rect = o.rect
//        if o is Model {
//            let m = o as! Model
//            let origin = float2(min(m.current_rect.x, m.rect.x), min(m.current_rect.y, m.rect.y))
//            rect = AABB(origin: origin, size: m.current_rect.get_size() + m.rect.get_size())
//        }
        let index = getIndex(rect)
        var list = [Object]()
        if nodes[0] != nil {
            if index != -1 {
                let l = nodes[index]!.retrieveList(o)
                list.appendContentsOf(l)
            } else {
                for i in 0..<4 {
                    let l = nodes[i]!.retrieveList(o)
                    list.appendContentsOf(l)
                }
            }
        }
        
        
        list.appendContentsOf(objects)
        list.appendContentsOf(models)
        return list
    }
    
    func printOut(){
        print("Level \(level) \(bounds)")
        for n in nodes {
            n?.printOut()
        }
    }
}