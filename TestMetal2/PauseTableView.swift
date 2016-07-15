//
//  PauseTableView.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-05.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation

enum PauseAction : Int {
    case Resume = 0
    case Restart
    case Exit
}
class PauseTableView : UITableView, UITableViewDataSource {
    
    var content = ["RESUME", "RESTART", "EXIT"]
    var selectedIndex = 0
    
    init(frame: CGRect) {
        super.init(frame: frame, style: UITableViewStyle.Plain)
        self.dataSource = self
        self.separatorColor = UIColor.clearColor()
        self.registerNib(UINib(nibName: "PauseTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "PauseCell")
        self.rowHeight = 88
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func selectPrevious(){
        selectedIndex -= 1;
        selectedIndex = selectedIndex % content.count
        self.reloadData()
    }
    func selectNext(){
        selectedIndex += 1;
        selectedIndex = selectedIndex % content.count
        self.reloadData()
    }
    
    func selectCurrent(){
        self.delegate?.tableView!(self, didSelectRowAtIndexPath: getCurrentIndex())
    }
    func getCurrentIndex() -> NSIndexPath {
        return NSIndexPath(forRow: selectedIndex, inSection: 0)
    }
    
    func numberOfSectionsInTableView(tableView : UITableView) -> NSInteger {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PauseCell") as! PauseTableViewCell
        cell.backgroundColor = UIColor.clearColor()
        
        let action = content[indexPath.row]
        cell.label?.text = action
        cell.selectionView?.hidden = selectedIndex != indexPath.row
        return cell
    }
    


}

class PauseTableViewCell : UITableViewCell {
    @IBOutlet var label : UILabel?
    @IBOutlet var selectionView : UIView?
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
