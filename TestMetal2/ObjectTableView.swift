//
//  ObjectTableView.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-06.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation

class ObjectTableView : UITableView, UITableViewDataSource {
    
    let content = [ObjectIDs.Cube, .Player, .Ghost]
    
    init(frame: CGRect) {
        super.init(frame: frame, style: UITableViewStyle.Plain)
        self.dataSource = self
        self.separatorColor = UIColor.clearColor()
        self.registerNib(UINib(nibName: "ObjectCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "ObjectCell")
        self.rowHeight = frame.size.width
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dataSource = self
        self.separatorColor = UIColor.clearColor()
        self.registerNib(UINib(nibName: "ObjectCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: "ObjectCell")
        self.rowHeight = self.frame.size.width
    }
    
    func numberOfSectionsInTableView(tableView : UITableView) -> NSInteger {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return content.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ObjectCell") as! ObjectCell
        cell.backgroundColor = UIColor.clearColor()
        let image = imageForObjectID(content[indexPath.row])
        cell.objectImageView!.image = image
        return cell
    }
    
    func imageForObjectID(oid : ObjectIDs) -> UIImage {
        switch(oid){
        case .Cube:
            return UIImage(named: "Block_None.png")!
        case .Player:
            return UIImage(named: "Texture.png")!
        case .Ghost:
            return UIImage(named: "Ghost.png")!
        }
    }
}

class ObjectCell : UITableViewCell {
    @IBOutlet var objectImageView : UIImageView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

