//
//  LevelEditor2ViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-01-18.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class LevelEditor2ViewController: UIViewController, UITextFieldDelegate {
    var lvl = Level()
    @IBOutlet var scrollView    : UIScrollView?
    @IBOutlet var nameField     : UITextField?
    
    override func viewDidLoad() {
        
//        #if TARGET_OS_IOS
        let tapper = UITapGestureRecognizer(target: self, action: "tapped:")
        self.scrollView!.addGestureRecognizer(tapper)
//        #endif
        
        self.scrollView!.bounces = false
        self.scrollView!.contentSize = CGSizeMake(2000, 1000)
        self.scrollView!.contentOffset = CGPoint(x: 0, y: scrollView!.contentSize.height - scrollView!.frame.height)
        let gridView = GridView(frame: CGRect(x: 0, y: 0, width: scrollView!.contentSize.width, height: scrollView!.contentSize.height))
        self.scrollView!.addSubview(gridView)
        
//        lvl.importLevel("test.lvl")
        for o in lvl.objects {
            let _ = ObjectIDs(rawValue: o.id)
            addBlockInGrid(Int(o.x_pos), grid_y: Int(o.y_pos))
        }
        self.nameField?.text = lvl.name
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        lvl.export()
        CloudConnect.uploadLevel(&lvl)
    }
    
    func tapped(tapper : UITapGestureRecognizer) {
        let location = tapper.locationInView(self.scrollView)
        let loc2d = CGPoint(x: location.x, y: self.scrollView!.contentSize.height - location.y)
        
        print("loction \(loc2d)")
        
        let grid_pos_x = Int(loc2d.x / 40)
        let grid_pos_y = Int(loc2d.y / 40)
        
        print("grid x\(grid_pos_x)y\(grid_pos_y)")
        addBlockInGrid(grid_pos_x, grid_y: grid_pos_y)
        addToLevel(grid_pos_x, grid_y: grid_pos_y)
    }
    
    func addBlockInGrid(grid_x : Int, grid_y : Int){
        let view = UIView(frame: CGRect(x: CGFloat(grid_x * 40), y: self.scrollView!.contentSize.height - CGFloat((grid_y+1) * 40), width: CGFloat(40), height: CGFloat(40)))
        view.backgroundColor = UIColor.yellowColor()
        self.scrollView!.addSubview(view)
    }
    
    func addToLevel(grid_x : Int, grid_y : Int){
        let object = LevelObject(0, .Block, UInt16(grid_x), UInt16(grid_y))
        lvl.objects.append(object)
    }
    
    
    func textFieldDidEndEditing(textField: UITextField) {
        lvl.name = textField.text!
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func saveButtonTapped(button : UIButton){
        lvl.export()
        CloudConnect.uploadLevel(&lvl)
    }
}
