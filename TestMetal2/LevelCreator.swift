//
//  LevelCreator.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-30.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import CloudKit

class LevelCreator {
    
    class func export(inout lvl : Level){
        var height : UInt16 = 0
        var width : UInt16  = 0
        var nr_objects : UInt16 = 0
        
        var pos_map = [String : Bool]()
        let objects_data = NSMutableData()
        
        for o in lvl.objects {
            //            var o_id = o.id
            //            var o_type = o.type
            let o_x = o.x_pos
            let o_y = o.y_pos
            
            if pos_map["\(o_x).\(o_y)"] != true {
                //                objects_data.appendBytes(&o_id, length: sizeof(UInt16))
                //                objects_data.appendBytes(&o_type, length: sizeof(UInt8))
                //                objects_data.appendBytes(&o_x, length: sizeof(UInt16))
                //                objects_data.appendBytes(&o_y, length: sizeof(UInt16))
                objects_data.appendData(o.export())
                pos_map["\(o_x).\(o_y)"] = true
                nr_objects += 1
                width = max(width, o_x)
                height = max(height, o_y)
            } else {
                print("Duplicate on \(o_x).\(o_y)")
            }
        }
        
        let c_name = lvl.name.dataUsingEncoding(NSUTF8StringEncoding)!
        var name_length : UInt16 = UInt16(c_name.length)
        var id_length : UInt16 = 0
        var id_name = NSData()
        if lvl.recordID?.recordName != nil {
            id_name = lvl.recordID!.recordName.dataUsingEncoding(NSUTF8StringEncoding)!
            id_length = UInt16(id_name.length)
            print("Export id \(lvl.recordID!.recordName)")
        }
        let header_data = NSMutableData()
        header_data.appendBytes(&lvl.id, length: sizeof(UInt32))
        header_data.appendBytes(&width, length: sizeof(UInt16))
        header_data.appendBytes(&height, length: sizeof(UInt16))
        header_data.appendBytes(&nr_objects, length: sizeof(UInt16))
        header_data.appendBytes(&name_length, length: sizeof(UInt16))
        header_data.appendBytes(&id_length, length: sizeof(UInt16))
        header_data.appendData(c_name)
        header_data.appendData(id_name)
        
        let level_data = NSMutableData()
        level_data.appendBytes(header_data.bytes, length: header_data.length)
        level_data.appendBytes(objects_data.bytes, length: objects_data.length)
        
        lvl.url = saveData(level_data, toName: "test.lvl")
    }
    
    class func importLevel(inout lvl : Level, lvlName : String){
        let fileURL = getURLforName(lvlName)
        importLevel(&lvl, fileURL:fileURL)
    }
    class func importLevel(inout lvl : Level, fileURL : NSURL) {
        let data = loadData(fileURL: fileURL)
        importLevel(&lvl, level_data: data)
    }
    class func importLevel(inout lvl : Level, assetURL : NSURL) {
        let data = loadData(assetURL: assetURL)
        importLevel(&lvl, level_data: data)
    }
    
    
    class func importLevel(inout lvl : Level, level_data : NSData?) {
        guard level_data != nil else {
            print("ERROR, load data is nil")
            return
        }
    
        var id : UInt32 = 0
        var lvl_width : UInt16 = 0
        var lvl_height : UInt16 = 0
        var nr_objects : UInt16 = 0
        var name_length : UInt16 = 0
        var id_length : UInt16 = 0
        var name_buf = NSData()
        var id_buf = NSData()
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
        
        level_data?.getBytes(&name_length, range: range)
        range.location += range.length
        
        level_data?.getBytes(&id_length, range: range)
        range.location += range.length
        
        range.length = Int(name_length)
        name_buf = level_data!.subdataWithRange(range)
        range.location += range.length
        
        range.length = Int(id_length)
        id_buf = level_data!.subdataWithRange(range)
        range.location += range.length
        
        let foo_name = String(data: name_buf, encoding: NSUTF8StringEncoding)
        if foo_name != nil {
            lvl.name = foo_name!
        } else {
            print("ERROR, couldn't import name")
        }
        
        let foo_id = String(data: id_buf, encoding: NSUTF8StringEncoding)
        if foo_id != nil && foo_id?.characters.count > 0 {
            lvl.recordID = CKRecordID(recordName: foo_id!)
        } else {
            print("ERROR, couldn't import name")
        }
        
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
            lvl.objects.append(o)
        }
        
        for i in 0...max_x {
            let temp = [Bool](count: Int(max_y+1), repeatedValue: false)
            lvl.filled_grid.insert(temp, atIndex: Int(i))
        }
        
        for lo in lvl.objects {
            lvl.filled_grid[Int(lo.x_pos)][Int(lo.y_pos)] = true
        }
        
        for lo in lvl.objects {
            
            let left = GridPoint(x: Int(lo.x_pos)-1, y: Int(lo.y_pos))
            let right = GridPoint(x: Int(lo.x_pos)+1, y: Int(lo.y_pos))
            let bottom = GridPoint(x: Int(lo.x_pos), y: Int(lo.y_pos)-1)
            let top = GridPoint(x: Int(lo.x_pos), y: Int(lo.y_pos)+1)
            
            
            var bit : UInt8 = 0
            if in_range_filled_grid(top, filled_grid: lvl.filled_grid) && lvl.filled_grid[top.x][top.y]{
                bit = bit | 0b1000
            }
            if in_range_filled_grid(bottom, filled_grid: lvl.filled_grid) && lvl.filled_grid[bottom.x][bottom.y]{
                bit = bit | 0b0010
            }
            if in_range_filled_grid(left, filled_grid: lvl.filled_grid) && lvl.filled_grid[left.x][left.y]{
                bit = bit | 0b0001
            }
            if in_range_filled_grid(right, filled_grid: lvl.filled_grid) && lvl.filled_grid[right.x][right.y]{
                bit = bit | 0b0100
            }
            
            
            if lo.x_pos >= 10 {
                print("lo \(lo.x_pos) \(lo.y_pos) \(bit)")
                
            }
            lo.can_rest = bit == 0b1111
            lo.collision_bit = bit
        }
        
    }
    
    
    class func readBuffer<T>(data : NSData, inout v : T, inout range : NSRange){
        range.length = sizeof(T)
        data.getBytes(&v, range: range)
        range.location += range.length
    }
    
   class  func saveData(data : NSData, toName name : String) -> NSURL{
        let url = getURLforName(name)
        let didWrite = data.writeToFile(url.absoluteString, atomically: true)
    
        if !didWrite {
            print("ERROR writing to \(url.absoluteString)")
        } else {
            print("Did write level to \(url.absoluteString)")
        }
        return url
    }
    
    class func loadData(fileURL url : NSURL) -> NSData? {
        let data = NSData(contentsOfFile: url.absoluteString)
        return data
    }
    class func loadData(assetURL url : NSURL) -> NSData? {
        let data = NSData(contentsOfURL: url)
        return data
    }
    
    class func getURLforName(name : String) -> NSURL{
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let docs : String = paths[0] as String
        let docs_url = NSURL(string: docs)
        let responseData = docs_url?.URLByAppendingPathComponent(name)
        return responseData!
    }
    class func in_range_filled_grid(p : GridPoint, filled_grid : [[Bool]]) -> Bool{
        return p.x >= 0 && Int(p.x) < filled_grid.count && p.y >= 0 && Int(p.y) < filled_grid[Int(p.x)].count
    }
}