//
//  LevelSelectViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-30.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class LevelSelectViewController : SubGamePadController, UITableViewDataSource, UITableViewDelegate{
    @IBOutlet var tableView_o : UITableView?
    var tableView : UITableView {get { return tableView_o!}}
    var content = [LevelHandler]()
    var selectedIndex = NSIndexPath(forRow: 0, inSection: 0)

    override func viewDidLoad() {
        self.tableView.dataSource   = self
        self.tableView.delegate     = self
        self.tableView.registerNib(UINib(nibName: "LevelCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "cell")
        let levelDataList = NSUserDefaults.standardUserDefaults().valueForKey("UnfinishedLevels") as? [NSData]
        if levelDataList != nil {
            for d in levelDataList! {
                let lvlHandler = NSKeyedUnarchiver.unarchiveObjectWithData(d) as! LevelHandler
                content.append(lvlHandler)
            }
            content.sortInPlace({ (l1, l2) -> Bool in
                return l1.lastModified.compare(l2.lastModified) == NSComparisonResult.OrderedDescending
            })
        }
        self.tableView.reloadData()
        self.tableView.selectRowAtIndexPath(selectedIndex, animated: false, scrollPosition: .Middle)
    }
    
    
    func numberOfSectionsInTableView(tableView : UITableView) -> NSInteger {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! LevelCell
    
        let lvl = content[indexPath.row]
        cell.label?.text = lvl.name
        cell.dateLabel?.text = cell.timeAgoSinceDate(lvl.lastModified, numericDates: true)
        print("lvl \(lvl.lastModified)")
        cell.delegate = self.tabController
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndex = indexPath
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {

        return true
    }
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let lvl = content.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
            removeFromUserDefaults(lvl)
        }
    }
    
    override func gamePadDidReleaseButton(button: Button) {
        switch(button){
        case .Down:
            let nxtRow = (selectedIndex.row+1) % tableView.numberOfRowsInSection(selectedIndex.section)
            selectedIndex = NSIndexPath(forRow: nxtRow, inSection: selectedIndex.section)
            tableView.selectRowAtIndexPath(selectedIndex, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        case .Up:
            let nxtRow = selectedIndex.row == 0 ? tableView.numberOfRowsInSection(selectedIndex.section)-1 : selectedIndex.row-1
            selectedIndex = NSIndexPath(forRow: nxtRow, inSection: selectedIndex.section)
            tableView.selectRowAtIndexPath(selectedIndex, animated: false, scrollPosition: UITableViewScrollPosition.Middle)
        case .A:
            let cell = tableView.cellForRowAtIndexPath(selectedIndex) as! LevelCell
            tabController?.cellDidTapEdit(cell)
        default:
            break
        }
    }
    
    
    func removeFromUserDefaults(level : LevelHandler){
        var array = NSUserDefaults.standardUserDefaults().valueForKey("UnfinishedLevels") as? [NSData]
        if array == nil {
            array = [NSData]()
        }
        var conv_arr = [LevelHandler]()
        for d in array!{
            let lh = NSKeyedUnarchiver.unarchiveObjectWithData(d) as! LevelHandler
            conv_arr.append(lh)
        }
        let index = conv_arr.indexOf { (lh) -> Bool in
            return lh.id == level.id
        }
        if index != nil {
            array!.removeAtIndex(index!)
        }
        
        NSUserDefaults.standardUserDefaults().setValue(array, forKey: "UnfinishedLevels")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

protocol LevelCellDelegate{
    func cellDidTapEdit(cell : LevelCell)
    
}
class LevelCell : UITableViewCell {
    @IBOutlet var label : UILabel?
    @IBOutlet var dateLabel : UILabel?
    
    var delegate : LevelCellDelegate?
    
    @IBAction func didTapEdit(button : UIButton){
        delegate?.cellDidTapEdit(self)
    }
    
    func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
        let calendar = NSCalendar.currentCalendar()
        let now = NSDate()
        let earliest = now.earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:NSDateComponents = calendar.components([NSCalendarUnit.Minute , NSCalendarUnit.Hour , NSCalendarUnit.Day , NSCalendarUnit.WeekOfYear , NSCalendarUnit.Month , NSCalendarUnit.Year , NSCalendarUnit.Second], fromDate: earliest, toDate: latest, options: NSCalendarOptions())
        
        if (components.year >= 2) {
            return "\(components.year) years ago"
        } else if (components.year >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month >= 2) {
            return "\(components.month) months ago"
        } else if (components.month >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear >= 2) {
            return "\(components.weekOfYear) weeks ago"
        } else if (components.weekOfYear >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day >= 2) {
            return "\(components.day) days ago"
        } else if (components.day >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour >= 2) {
            return "\(components.hour) hours ago"
        } else if (components.hour >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute >= 2) {
            return "\(components.minute) minutes ago"
        } else if (components.minute >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second >= 3) {
            return "\(components.second) seconds ago"
        } else {
            return "Just now"
        }
        
    }
}