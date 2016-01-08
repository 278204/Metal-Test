//
//  QuadTree.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import UIKit


typealias Rect_Obj = (rect : CGRect, model : Model)
class QuadTree{
    let MAX_OBJECTS = 10
    let MAX_LEVELS = 5
    
    let level : Int
    var objects = [Rect_Obj]()
    let bounds : CGRect
    var nodes : [QuadTree?]
    
    init(level l : Int, bounds b : CGRect){
        level = l
        bounds = b
        nodes = [QuadTree?](count: 4, repeatedValue: nil)
    }
    
    func clear(){
        objects.removeAll()
        
        for i in 0..<nodes.count {
            nodes[i]?.clear()
            nodes[i] = nil
        }
    }
    
    private func split(){
        
        let subWidth = CGFloat(bounds.width / 2)
        let subHeight = CGFloat(bounds.height / 2)
        
        let x = CGFloat(bounds.origin.x)
        let y = CGFloat(bounds.origin.y)
        
        nodes[0] = QuadTree(level: level+1, bounds: CGRect(x: x + subWidth, y: y, width: subWidth, height: subHeight))
        nodes[1] = QuadTree(level: level+1, bounds: CGRect(x: x, y: y, width: subWidth, height: subHeight))
        nodes[2] = QuadTree(level: level+1, bounds: CGRect(x: x, y: y + subHeight, width: subWidth, height: subHeight))
        nodes[3] = QuadTree(level: level+1, bounds: CGRect(x: x + subWidth, y: y + subHeight, width: subWidth, height: subHeight))
    }
    
    private func getIndex(rect : CGRect) -> Int{
        var index = -1
        let verticalMidPoint = bounds.origin.x + (bounds.width / 2)
        let horizontalMidPoint = bounds.origin.y + (bounds.height / 2)
        
        let topQuad = (rect.origin.y < horizontalMidPoint && rect.origin.y + rect.height < horizontalMidPoint)
        let bottomQuad = (rect.origin.y > horizontalMidPoint)
        
        if rect.origin.x < verticalMidPoint && rect.origin.x + rect.width < verticalMidPoint {
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
        
        return index
    }
    
    func insert(obj : Rect_Obj){
        if nodes[0] != nil {
            let index = getIndex(obj.rect)
            if index != -1 {
                nodes[index]?.insert(obj)
                return
            }
        }
        
        objects.append(obj)
        
        if objects.count > MAX_OBJECTS && level < MAX_LEVELS {
            if nodes[0] == nil {
                split()
            }
            
            var i = 0
            
            while i < objects.count {
                let index = getIndex(objects[i].rect)
                if index != -1 {
                    nodes[index]?.insert(objects[i])
                    objects.removeAtIndex(i)
                } else{
                    i += 1
                }
            }
        }
    }
    
    func retrieveList(rect : CGRect) -> [Rect_Obj] {
        let index = getIndex(rect)
        var list = [Rect_Obj]()
        if index != -1 && nodes[0] != nil {
            let l = nodes[index]!.retrieveList(rect)
            list.appendContentsOf(l)
        }
        
        list.appendContentsOf(objects)
        
        return list
    }
}