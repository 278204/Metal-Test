//
//  LevelEditor2ViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class LevelEditor2ViewController: UIViewController {
    let lvl = Level()
    
    override func viewDidLoad() {
        
        let gridView = GridView(frame: self.view.bounds)
        self.view.addSubview(gridView)
        
        let tapper = UITapGestureRecognizer(target: self, action: "tapped:")
        self.view.addGestureRecognizer(tapper)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        lvl.export()
    }
    
    func tapped(tapper : UITapGestureRecognizer) {
        let location = tapper.locationInView(self.view)
        let loc2d = CGPoint(x: location.x, y: self.view.frame.height - location.y)
        
        print("loction \(loc2d)")
        
        let grid_pos_x = Int(loc2d.x / 40)
        let grid_pos_y = Int(loc2d.y / 40)
        
        print("grid \(grid_pos_x) x \(grid_pos_y)")
        addBlockInGrid(grid_pos_x, grid_y: grid_pos_y)
    }
    
    func addBlockInGrid(grid_x : Int, grid_y : Int){
        let view = UIView(frame: CGRect(x: CGFloat(grid_x * 40), y: self.view.frame.size.height - CGFloat((grid_y+1) * 40), width: CGFloat(40), height: CGFloat(40)))
        view.backgroundColor = UIColor.yellowColor()
        self.view.addSubview(view)
        
        let object = LevelObject(0, .Block, UInt16(grid_x), UInt16(grid_y))
        lvl.objects.append(object)
    }
}
