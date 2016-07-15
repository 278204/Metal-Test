//
//  CloudConnect.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-28.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation
import CloudKit

class CloudConnect {

    class var db : CKDatabase {get { return CKContainer.defaultContainer().publicCloudDatabase}}
    
    class func uploadLevel(inout level : LevelHandler, completion : (CKRecord? -> Void)){
//        guard level.url != nil else {
//            print("ERROR, level url is nil")
//            completion(nil)
//            return
//        }
        
        if level.recordID == nil {
            uploadNewLevel(&level, completion: completion)
        } else {
            uploadChangedLevel(level, completion: completion)
        }
    }
    
    class func uploadCompletedLevel(level : LevelHandler, completion : (NSError? -> Void)){
        let record = level.getCompleteRecord()!
        db.saveRecord(record) { (record, error) -> Void in
            completion(error)
        }
    }
    
    class func uploadNewLevel(inout level : LevelHandler, completion : (CKRecord? -> Void)){
        
        let record = level.getRecord()
        if record == nil {
            print("Get record failed")
            completion(nil)
            return
        }
        db.saveRecord(record!) { (saved, error) -> Void in
            if error != nil {
                print("Save record went wrong \(error.debugDescription)")
                completion(nil)
            } else {
                print("Did save record")
                level.recordID = saved!.recordID
                completion(saved)
            }
        }
    }
    
    class func uploadChangedLevel(level : LevelHandler, completion : (CKRecord? -> Void)){
        guard level.recordID != nil else {
            print("Cant change level without record id")
            completion(nil)
            return
        }
        let record = level.getRecord()
        if record == nil {
            print("Get record failed")
            completion(nil)
            return
        }
        changedRecords([record!], completion: {error in
            if error == nil {
                print("Succeded in changing level")
            } else {
                print("ERROR changing level \(error.debugDescription)")
            }
            completion(record)
        })
    }
    
    class func changedRecords(records : [CKRecord], completion : (NSError? -> Void)) {
        guard records.count != 0 else {
            print("Cant changed 0 records")
            return
        }
        let saveRecordsOperation = CKModifyRecordsOperation()
    
        saveRecordsOperation.recordsToSave = records
        saveRecordsOperation.savePolicy = .ChangedKeys
        saveRecordsOperation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
            completion(error)
        }
        
        db.addOperation(saveRecordsOperation)
    }
    
    class func downloadLevel(name : String, completion : (CKRecord -> Void)){

        let predicate = NSPredicate(format: "Name = %@", name)
        let query = CKQuery(recordType: "Level", predicate: predicate)
        let query_op = CKQueryOperation(query: query)
        query_op.resultsLimit = 1
        query_op.recordFetchedBlock = {record in
            completion(record)
        }
        query_op.queryCompletionBlock = {cursor, error in
            if error != nil {
                print("ERROR \(error?.debugDescription)")
            }
        }
        db.addOperation(query_op)
  
    }
    
    class func downloadLevel(recordID : CKRecordID, completion : (CKRecord -> Void)){
        
        db.fetchRecordWithID(recordID) { (record, error) -> Void in
            if error != nil || record == nil{
                print("ERROR downloading level with record ID, \(error?.debugDescription)")
            } else {
                completion(record!)
            }
        }
    }
    
    class func downloadAllLevels(assets : Bool, completion : (CKRecord -> Void)){
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Level", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
       
        let query_op = CKQueryOperation(query: query)
        if !assets {
            query_op.desiredKeys = ["Name", "Score"]
        }
        query_op.recordFetchedBlock = {record in
            completion(record)
        }
        
        query_op.queryCompletionBlock = {(cursor, error) in
            if error != nil {
                print("ERROR Fetch all level went wrong \(error.debugDescription)")
            }
        }
        db.addOperation(query_op)
      
    }
    
}