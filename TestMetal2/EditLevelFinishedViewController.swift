//
//  EditLevelFinishedViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-11.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


class EditLevelFinishedViewController : OptionsController, UIViewControllerTransitioningDelegate {
    
    var level : LevelHandler?
    var uploading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard level != nil else {
            assertionFailure("Cant show editLevelFinished with no level")
            return
        }
    }
    
    @IBAction func backToEdit(button : UIButton?) {
        let levc = self.storyboard?.instantiateViewControllerWithIdentifier("levelEditorVC") as! LevelEditorViewController
        levc.level = level!
        self.presentViewController(levc, animated: false, completion: nil)
    }
    
    @IBAction func upload(button : UIButton?) {
        if !uploading {
            uploading = true
            CloudConnect.uploadCompletedLevel(level!) { (error) -> Void in
                if error != nil {
                    print("ERROR, upload complete level \(error.debugDescription)")
                } else {
                    print("SUCCESS uploading complete level")
                    self.saveLevelUserDefaults()
                }
            }
        }
    }
    
    func saveLevelUserDefaults(){
        let data = NSKeyedArchiver.archivedDataWithRootObject(level!)
        var array = NSUserDefaults.standardUserDefaults().valueForKey("UnfinishedLevels") as? [NSData]
        var finishedArray = NSUserDefaults.standardUserDefaults().valueForKey("SavedLevels") as? [NSData]
        
        if finishedArray == nil {
            finishedArray = [NSData]()
        }
        
        var conv_arr = [LevelHandler]()
        for d in array!{
            let lh = NSKeyedUnarchiver.unarchiveObjectWithData(d) as! LevelHandler
            conv_arr.append(lh)
        }
        let index = conv_arr.indexOf { (lh) -> Bool in
            return lh.id == self.level!.id
        }
        
        array!.removeAtIndex(index!)
        finishedArray!.append(data)
        
        NSUserDefaults.standardUserDefaults().setValue(finishedArray, forKey: "SavedLevels")
        NSUserDefaults.standardUserDefaults().setValue(array, forKey: "UnfinishedLevels")
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }

}