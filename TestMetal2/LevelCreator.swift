//
//  LevelCreator.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-16.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation



typealias GridPoint = (x : Int, y : Int)
enum ObjectType : UInt8{
    case Block = 0
    case Model
}

enum ObjectIDs : UInt16 {
    case Cube = 0
}

class LevelObject {
    var id : UInt16 = 0
    var type : ObjectType = .Block
    var x_pos : UInt16 = 0
    var y_pos : UInt16 = 0
    var can_rest = false
    var collision_bit : UInt8 = 0
    init(_ i : UInt16, _ t : ObjectType, _ x : UInt16, _ y : UInt16){
        id = i
        type = t
        x_pos = x
        y_pos = y
    }
    
    func printOut(){
        print("Object \(id), \(type), \(x_pos) \(y_pos)")
    }
}
class Level {
    var filled_grid = [[Bool]]()
    var objects = [LevelObject]()
    var name : String
    var id : UInt16
    
    init(){
        name = "unknown"
        id = 0
    }
    
    func export(){
        var height : UInt16 = 500
        var width : UInt16  = 0
        for o in objects where o.x_pos > width{
            width = o.x_pos
        }
        var nr_objects : UInt16 = UInt16(objects.count)
        let header_data = NSMutableData()
        
        header_data.appendBytes(&id, length: sizeof(UInt32))
        header_data.appendBytes(&width, length: sizeof(UInt16))
        header_data.appendBytes(&height, length: sizeof(UInt16))
        header_data.appendBytes(&nr_objects, length: sizeof(UInt16))
        
        
        let objects_data = NSMutableData()
        
        for o in objects {
            var o_id = o.id
            var o_type = o.type
            var o_x = o.x_pos
            var o_y = o.y_pos
            
            objects_data.appendBytes(&o_id, length: sizeof(UInt16))
            objects_data.appendBytes(&o_type, length: sizeof(UInt8))
            objects_data.appendBytes(&o_x, length: sizeof(UInt16))
            objects_data.appendBytes(&o_y, length: sizeof(UInt16))
        }
        
        let level_data = NSMutableData()
        
        level_data.appendBytes(header_data.bytes, length: header_data.length)
        level_data.appendBytes(objects_data.bytes, length: objects_data.length)
        
        saveData(level_data, toName: "test.lvl")
    }
    
    func importLevel(lvlName : String){
        let level_data = loadData(lvlName)
        
        guard level_data != nil else {
            print("ERROR, load data for \(lvlName) is nil")
            return
        }
        
        
        var id : UInt32 = 0
        var lvl_width : UInt16 = 0
        var lvl_height : UInt16 = 0
        var nr_objects : UInt16 = 0
        var range = NSMakeRange(0, sizeof(UInt32))
        
        level_data?.getBytes(&id, range: range)
        range.location = range.length
        range.length = sizeof(UInt16)
        
        level_data?.getBytes(&lvl_width, range: range)
        range.location += range.length
        
        level_data?.getBytes(&lvl_height, range: range)
        range.location += range.length
        
        level_data?.getBytes(&nr_objects, range: range)
        range.location += range.length
        
        var max_x : UInt16 = 0
        var max_y : UInt16 = 0
        for _ in 0..<nr_objects {
            var o_id : UInt16 = 0
            var o_type : ObjectType = .Block
            var o_x : UInt16 = 0
            var o_y : UInt16 = 0
            

            readBuffer(level_data!, v: &o_id, range: &range)
            readBuffer(level_data!, v: &o_type, range: &range)
            readBuffer(level_data!, v: &o_x, range: &range)
            readBuffer(level_data!, v: &o_y, range: &range)
            
            max_x = max(o_x, max_x)
            max_y = max(o_y, max_y)
            
            let o = LevelObject(o_id, o_type, o_x, o_y)
            objects.append(o)
        }
        
        for i in 0...max_x {
            let temp = [Bool](count: Int(max_y+1), repeatedValue: false)
            filled_grid.insert(temp, atIndex: Int(i))
        }
        
        for lo in objects {
            filled_grid[Int(lo.x_pos)][Int(lo.y_pos)] = true
        }
        
        for lo in objects {

            let left = GridPoint(x: Int(lo.x_pos)-1, y: Int(lo.y_pos))
            let right = GridPoint(x: Int(lo.x_pos)+1, y: Int(lo.y_pos))
            let bottom = GridPoint(x: Int(lo.x_pos), y: Int(lo.y_pos)-1)
            let top = GridPoint(x: Int(lo.x_pos), y: Int(lo.y_pos)+1)
            
            
            var bit : UInt8 = 0
            if in_range_filled_grid(top) && filled_grid[top.x][top.y]{
                bit = bit | 0b1000
            }
            if in_range_filled_grid(bottom) && filled_grid[bottom.x][bottom.y]{
                bit = bit | 0b0010
            }
            if in_range_filled_grid(left) && filled_grid[left.x][left.y]{
                bit = bit | 0b0001
            }
            if in_range_filled_grid(right) && filled_grid[right.x][right.y]{
                bit = bit | 0b0100
            }
            
            
            if lo.x_pos >= 20 {
                print("lo \(lo.x_pos) \(lo.y_pos) \(bit)")
                
            }
            lo.can_rest = bit == 0b1111
            lo.collision_bit = bit
        }
        
    }
    
    
    func readBuffer<T>(data : NSData, inout v : T, inout range : NSRange){
        range.length = sizeof(T)
        data.getBytes(&v, range: range)
        range.location += range.length
    }
    
    func saveData(data : NSData, toName name : String){
        let responseData = getURLforName(name)
        let didWrite = data.writeToFile(responseData.absoluteString, atomically: true)
        
        if !didWrite {
            print("ERROR writing to \(responseData.absoluteString)")
        } else {
            print("Did write level to \(responseData.absoluteString)")
        }
    }
    
    func loadData(name : String) -> NSData? {
        let responseData = getURLforName(name)
        let data = NSData(contentsOfFile: responseData.absoluteString)
        return data
    }
    
    func getURLforName(name : String) -> NSURL{
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docs : String = paths[0] as String
        let docs_url = NSURL(string: docs)
        let responseData = docs_url?.URLByAppendingPathComponent(name)
        return responseData!
    }
    
    func in_range_filled_grid(p : GridPoint) -> Bool{
        return p.x >= 0 && Int(p.x) < filled_grid.count && p.y >= 0 && Int(p.y) < filled_grid[Int(p.x)].count
    }
}