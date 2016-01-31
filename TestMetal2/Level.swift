//
//  LevelCreator.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-16.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import CloudKit


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
    
    func export()-> NSData{
        let objects_data = NSMutableData()
        objects_data.appendBytes(&id, length: sizeof(UInt16))
        objects_data.appendBytes(&type, length: sizeof(UInt8))
        objects_data.appendBytes(&x_pos, length: sizeof(UInt16))
        objects_data.appendBytes(&y_pos, length: sizeof(UInt16))
        return objects_data
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
    var url : NSURL?
    var recordID : CKRecordID?
    
    init(){
        name = "unknown"
        id = 0
    }

    func export(){
        var temp = self
        LevelCreator.export(&temp)
    }
    
    func importLevel(name : String){
        var temp = self
        LevelCreator.importLevel(&temp, lvlName: name)
    }
        
    func getRecord() -> CKRecord?{
        guard url != nil else {
            print("Cant create record for level which haven't exported to file")
            return nil
        }
        let asset = CKAsset(fileURL: NSURL(fileURLWithPath: url!.absoluteString))
        var record = CKRecord(recordType: "Level")
        if recordID != nil {
            record = CKRecord(recordType: "Level", recordID: recordID!)
        }
        record["Created"] = NSDate()
        record["Score"] = 0
        record["Name"] = name
        record["File"] = asset
        return record
    }

    func setRecord(record : CKRecord){
        self.name = record["Name"] as! String
        self.recordID = record.recordID
        
        if record["File"] != nil {
            let asset = record["File"] as! CKAsset
            self.url = asset.fileURL
            var temp = self
            LevelCreator.importLevel(&temp, assetURL: asset.fileURL)
        }
    }
    
    func download(completion : (Void -> Void)){
        guard self.url == nil else {
            print("Level already got url")
            return
        }
        
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
}