//
//  LevelCreator.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-16.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import CloudKit
import simd

typealias GridPoint = (x : Int, y : Int)

enum ObjectType : UInt8{
    case Block = 0
    case Dynamic
}

enum ObjectIDs : UInt16 {
    case Cube = 0
    case Player
    case Ghost
}


class LevelObject {
    var id : ObjectIDs
    var type : ObjectType = .Block
    var x_pos : UInt16 = 0
    var y_pos : UInt16 = 0
    var can_rest = false
    var collision_side_bit : UInt8 = 0
    
    init(object : Object) {
        if object.dynamic {
            type = .Dynamic
        }
        
        x_pos = UInt16(object.gridPos.x)
        y_pos = UInt16(object.gridPos.y)
        can_rest = object.can_rest
        collision_side_bit = object.collision_side_bit
        id = LevelData.idForObject(object)
    }
    
    init(_ i : ObjectIDs, _ t : ObjectType, _ x : UInt16, _ y : UInt16){
        id = i
        type = t
        x_pos = x
        y_pos = y
    }
    
    func export()-> NSData{
        let objects_data = NSMutableData()
        objects_data.appendBytes(&id, length: sizeof(ObjectIDs))
        objects_data.appendBytes(&type, length: sizeof(ObjectType))
        objects_data.appendBytes(&x_pos, length: sizeof(UInt16))
        objects_data.appendBytes(&y_pos, length: sizeof(UInt16))
        objects_data.appendBytes(&collision_side_bit, length: sizeof(UInt8))
        return objects_data
    }
    
    
    func printOut(){
        print("Object \(id), \(type), \(x_pos) \(y_pos)")
    }
}

class LevelHandler : NSObject, NSCoding{
    
    var name : String
    var id : UInt32
    var recordID : CKRecordID?
    var lastModified = NSDate()
    var lastUploaded = NSDate()
    var inCloud : Bool { get { return lastUploaded.compare(lastModified) == NSComparisonResult.OrderedDescending}}
    var data : LevelData?
    
    override init(){
        name = "unknown"
        //WARNING, must check it doesn't already exist locally
        id = arc4random_uniform(UInt32.max)
    }
    
    func export(){
        guard data != nil else {
            print("ERROR, cant export level with no leveldata")
            return
        }
        data!.updateLevelObjects()
        LevelCreator.export(self)
    }
    
    func importSelf(){
        importLevel(self.id)
    }
    func importLevel(lvlID : UInt32){
        id = lvlID
        var temp = self
        self.data = LevelData()
        LevelCreator.importLevel(&temp, lvlName: "\(lvlID).lvl")
    }
    
    func getRecord() -> CKRecord?{
//        guard url != nil else {
//            print("Cant create record for level which haven't exported to file")
//            return nil
//        }
        let url = LevelCreator.getURLforName("\(id).lvl")
        
        let asset = CKAsset(fileURL: NSURL(fileURLWithPath: url.absoluteString))
        var record = CKRecord(recordType: "UnfinishedLevel")
        if recordID != nil {
            record = CKRecord(recordType: "UnfinishedLevel", recordID: recordID!)
        }
        record["Name"] = name
        record["File"] = asset
        record["LocalID"] = NSNumber(unsignedInt: self.id)
        
        return record
    }
    func getCompleteRecord() -> CKRecord?{

        let url = LevelCreator.getURLforName("\(id).lvl")
        
        let asset = CKAsset(fileURL: NSURL(fileURLWithPath: url.absoluteString))
        let record = CKRecord(recordType: "Level")
        
        record["Name"] = name
        record["File"] = asset
        record["Created"] = NSDate()
        record["Score"] = NSNumber(int: 0)
        
        return record
    }
    
    func setRecord(record : CKRecord){
        self.name = record["Name"] as! String
        self.recordID = record.recordID
        
        if record["File"] != nil {
            let asset = record["File"] as! CKAsset
            var temp = self
            LevelCreator.importLevel(&temp, assetURL: asset.fileURL)
        }
    }
    
    func download(completion : (Void -> Void)){
        
        if self.recordID != nil {
            CloudConnect.downloadLevel(self.recordID!) { (record) -> Void in
                self.setRecord(record)
                completion()
            }
        } else {
            CloudConnect.downloadLevel(self.name, completion: { (record) -> Void in
                self.setRecord(record)
                completion()
            })
        }
        
    }
    
    //MARK: - NSCoding -
    required init(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as! String
        id = (aDecoder.decodeObjectForKey("id") as! NSNumber).unsignedIntValue
        let recordName = aDecoder.decodeObjectForKey("recordID") as? String
        if recordName != nil {
            recordID = CKRecordID(recordName: recordName!)
        }
        lastModified = aDecoder.decodeObjectForKey("lastModified") as! NSDate
        lastUploaded = aDecoder.decodeObjectForKey("lastUploaded") as! NSDate
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(NSNumber(unsignedInt: id), forKey: "id")
        aCoder.encodeObject(recordID?.recordName, forKey: "recordID")
        aCoder.encodeObject(lastModified, forKey: "lastModified")
        aCoder.encodeObject(lastUploaded, forKey: "lastUploaded")
    }
    
}

protocol LevelDataDelegate{
    func levelDataDidRestore(ld : LevelData)
}

class LevelData {
    var delegate : LevelDataDelegate?
    var lvlObjects = [LevelObject]()
    var grid = [[Object?]](count: Settings.maxGridPoint.x, repeatedValue: [Object?](count: Settings.maxGridPoint.y, repeatedValue: nil))
    var objects = [Object]()
    var dynamics = [Object]()
    var max_x : Int = 0
    init(){
        
    }
    
    func addObject(o : Object, point : GridPoint){
        if o.dynamic {
            if o is Player {
                if getPlayerObject() != nil {
                    print("ERROR Cant add multiple players")
                    return
                }
            }
            dynamics.append(o)
        } else {
            grid[point.x][point.y] = o
            
            let left = GridPoint(x: point.x-1, y: point.y)
            let right = GridPoint(x: point.x+1, y: point.y)
            let bottom = GridPoint(x: point.x, y: point.y-1)
            let top = GridPoint(x: point.x, y: point.y+1)
            
            updateCollisionBitsForPoint(point)
            updateCollisionBitsForPoint(left)
            updateCollisionBitsForPoint(right)
            updateCollisionBitsForPoint(bottom)
            updateCollisionBitsForPoint(top)
        }
        objects.append(o)
    }
    
    func updateCollisionBitsForPoint(point : GridPoint){
        
        guard LevelData.insideGrid(point, grid: grid) && grid[point.x][point.y] != nil else {
            return
        }
        
        let left = GridPoint(x: point.x-1, y: point.y)
        let right = GridPoint(x: point.x+1, y: point.y)
        let bottom = GridPoint(x: point.x, y: point.y-1)
        let top = GridPoint(x: point.x, y: point.y+1)
        
        var bit : UInt8 = 0
        let o = grid[point.x][point.y]!
        if !o.dynamic{
            //WARNING, check for none dynamic object not nil?
            if LevelData.insideGrid(top, grid: grid) && grid[top.x][top.y]?.dynamic == false{
                bit = bit | 0b1000
            }
            if LevelData.insideGrid(bottom, grid: grid) && grid[bottom.x][bottom.y]?.dynamic == false{
                bit = bit | 0b0010
            }
            if LevelData.insideGrid(left, grid: grid) && grid[left.x][left.y]?.dynamic == false{
                bit = bit | 0b0001
            }
            if LevelData.insideGrid(right, grid: grid) && grid[right.x][right.y]?.dynamic == false{
                bit = bit | 0b0100
            }
        }
        o.collision_side_bit = bit
        o.can_rest = bit == 0b1111
    }
    
    func removeObject(o : Object){
        let index = objects.indexOf { (lo) -> Bool in
            return lo === o
        }
        objects.removeAtIndex(index!)
        if o.dynamic {
            let i_d = dynamics.indexOf { (lo) -> Bool in
                return lo === o
            }
            dynamics.removeAtIndex(i_d!)
        } else {
            let point = o.gridPos
            grid[o.gridPos.x][o.gridPos.y] = nil
            
            let left = GridPoint(x: point.x-1, y: point.y)
            let right = GridPoint(x: point.x+1, y: point.y)
            let bottom = GridPoint(x: point.x, y: point.y-1)
            let top = GridPoint(x: point.x, y: point.y+1)
            
            updateCollisionBitsForPoint(left)
            updateCollisionBitsForPoint(right)
            updateCollisionBitsForPoint(bottom)
            updateCollisionBitsForPoint(top)
            
        }
    }
    
    func updateLevelObjects(){
        lvlObjects.removeAll()
        for o in objects {
            let lo = LevelObject(object: o)
            lvlObjects.append(lo)
        }
    }

    
    func restore(){
        reset()
        updateLevelFromLevelObjects()
        self.delegate?.levelDataDidRestore(self)
    }
    func reset(){
        objects.removeAll()
        grid[0].removeAll()
        grid.removeAll()
        dynamics.removeAll()
    }
    
    func updateLevelFromLevelObjects(){
        grid = [[Object?]](count: Settings.maxGridPoint.x, repeatedValue: [Object?](count: Settings.maxGridPoint.y, repeatedValue: nil))
        
        max_x = 0
        for lo in lvlObjects {
            let o = LevelData.objectForID(lo.id)
            o.collision_side_bit = lo.collision_side_bit
            o.can_rest = lo.can_rest
            o.gridPos = GridPoint(x:Int(lo.x_pos), y:Int(lo.y_pos))
            o.moveTo(float3(Float(lo.x_pos) * Settings.gridSize, Float(lo.y_pos) * Settings.gridSize, 0))
            objects.append(o)
            
            if o.dynamic {
                dynamics.append(o)
            } else {
                grid[Int(lo.x_pos)][Int(lo.y_pos)] = o
            }
            max_x = max(max_x, Int(lo.x_pos))
        }
    }
    
    func getPlayerObject() -> Player?{
        let index = dynamics.indexOf { (o) -> Bool in
            return o is Player
        }
        if index == nil {
            return nil
        }
        
        return dynamics[index!] as? Player
    }
        

    class func insideGrid<T>(p : GridPoint, grid : [[T]]) -> Bool{
        return p.x >= 0 && Int(p.x) < grid.count && p.y >= 0 && Int(p.y) < grid[Int(p.x)].count
    }
    
    class func objectForID(oid : ObjectIDs) -> Object {
        switch(oid){
        case .Cube:
            return Cube()
        case .Player:
            return Player()
        case .Ghost:
            return Ghost()
        }
    }
    
    class func idForObject(o : Object) -> ObjectIDs {
        if o is Cube {
            return .Cube
        } else if o is Player {
            return .Player
        } else if o is Ghost {
            return .Ghost
        }
        return .Cube
    }
}