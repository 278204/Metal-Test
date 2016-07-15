//
//  OptionsController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-15.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class OptionsController: SubGamePadController {

    @IBOutlet var stackView : UIStackView?
    @IBOutlet var selectImageView : UIImageView?
    var currentIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for s in stackView!.subviews {
            let button = s.subviews[0] as! UIButton
            button.titleLabel?.textAlignment = NSTextAlignment.Center
            button.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        
    }

    override func viewDidAppear(animated: Bool) {
        updateIndex()
    }
    
    func buttonTapped(button : UIButton) {
        let view = button.superview
        let index = self.stackView!.subviews.indexOf(view!)
        currentIndex = index!
        updateIndex()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func selectIndex(index : Int){
        let button = stackView!.subviews[index].subviews[0] as! UIButton
        button.sendActionsForControlEvents(.TouchUpInside)
    }
    
    func updateIndex(){
        
        let button = stackView!.subviews[currentIndex]
        
        UIView.animateWithDuration(0.2) { () -> Void in
            for s in self.stackView!.subviews {
                s.alpha = 0.2
            }
            button.alpha = 1.0
            self.selectImageView?.center.x = button.center.x + self.stackView!.frame.origin.x
        }
        
    }
    
    override func gamePadDidPressButton(button: Button) {
        var updated = false
        switch(button){
        case .Right:
            currentIndex += 1
            updated = true
        case .Left:
            currentIndex -= 1
            updated = true
        case .A:
            selectIndex(currentIndex)
        default:
            break
        }
        if updated {
            currentIndex = currentIndex%stackView!.subviews.count
            if currentIndex < 0 {
                currentIndex = stackView!.subviews.count-1
            }
            updateIndex()
        }
    }
    
    override func gamePadDidReleaseButton(button: Button) {
        
        
    }
    
    override func gamePadDidPressPause() {

    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
