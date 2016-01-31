//
//  LevelSelectViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-30.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class LevelSelectViewController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet var tableView_o : UITableView?
    var tableView : UITableView {get { return tableView_o!}}
    var content = [Level]()
    
    override func viewDidLoad() {
        self.tableView.delegate     = self
        self.tableView.dataSource   = self
        CloudConnect.downloadAllLevels(false) { (record) -> Void in
                let lvl = Level()
                lvl.setRecord(record)
                self.content.append(lvl)
            
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
        }
    }
    
    @IBAction func didTapNewButton(button : UIButton){
        let lev = self.storyboard?.instantiateViewControllerWithIdentifier("leveEditorVC") as! LevelEditor2ViewController
        self.presentViewController(lev, animated: true, completion: nil)
    }
    
    func numberOfSectionsInTableView(tableView : UITableView) -> NSInteger {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        let lvl = content[indexPath.row]
        cell!.textLabel?.text = lvl.name
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let lvl = content[indexPath.row]
        print("Should start playin \(lvl.name)")
        lvl.download { () -> Void in
            let gvc = self.storyboard?.instantiateViewControllerWithIdentifier("gameVC") as! GameViewController
            gvc.level = lvl
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.presentViewController(gvc, animated: false, completion: nil)
            })
        }
    }

}
