//
//  TabController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-15.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import UIKit

class GamePadController : UIViewController, GamePadDelegate{
    
    override func viewDidLoad() {
        GamePad.shared.reset()
        GamePad.shared.delegate = self
    }
    
    func gamePadDidPressButton(button: Button) {
    }
    
    func gamePadDidReleaseButton(button: Button) {
    }
    
    func gamePadDidPressPause() {
        
    }
}

class SubGamePadController : UIViewController {
    var tabController : TabController?
    func gamePadDidPressButton(button: Button) {
    }
    
    func gamePadDidReleaseButton(button: Button) {
    }
    
    func gamePadDidPressPause() {
        
    }
}

class TabController: GamePadController, LevelCellDelegate {

    @IBOutlet var tabbar : UIView?
    var playViewController : SubGamePadController
    var editViewController : SubGamePadController
    var currentViewController : SubGamePadController
    var transitioning = false
    var displayLink : CADisplayLink?
    
    required init?(coder aDecoder: NSCoder) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        playViewController = storyboard.instantiateViewControllerWithIdentifier("Play") as! SubGamePadController
        editViewController = storyboard.instantiateViewControllerWithIdentifier("LevelSelect") as! SubGamePadController
        currentViewController = playViewController
        
        super.init(coder: aDecoder)
        
        playViewController.tabController = self
        editViewController.tabController = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        playViewController.view.frame.size.height -= self.tabbar!.frame.height
//        editViewController.view.frame.size.height -= self.tabbar!.frame.height
        
        self.view.insertSubview(playViewController.view, belowSubview: self.tabbar!)
        currentViewController = playViewController
    }
    
    override func viewDidAppear(animated: Bool) {
        self.displayLink = UIScreen.mainScreen().displayLinkWithTarget(self, selector: "displayDidLinkFire:")
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    override func viewWillDisappear(animated: Bool) {
        self.displayLink?.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    func displayDidLinkFire(dLink : CADisplayLink){
        if GamePad.shared.controllerConnected {
            GamePad.shared.checkButtons()
        }
    }

    @IBAction func changeToPlayViewController(button : UIButton?){
        guard currentViewController !== playViewController && !transitioning else {
            return
        }
        
       transition(playViewController, offset: -self.view.bounds.width)
    }
    
    
    @IBAction func changeToEditViewController(button : UIButton?){
        guard currentViewController !== editViewController && !transitioning else {
            return
        }
    
        transition(editViewController, offset: self.view.bounds.width)
    }
    
    func transition(transitonVC : SubGamePadController, offset : CGFloat){
        transition(transitonVC, offset: offset, completion: nil)
    }
    
    func transition(transitonVC : SubGamePadController, offset : CGFloat, completion : (()->())?){
        transitioning = true
        transitonVC.view.transform = CGAffineTransformMakeTranslation(offset, 0)
        self.view.insertSubview(transitonVC.view, belowSubview: self.tabbar!)
        
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.currentViewController.view.transform = CGAffineTransformMakeTranslation(-offset, 0)
            transitonVC.view.transform = CGAffineTransformMakeTranslation(0, 0)
            }) { (completed) -> Void in
                
                self.currentViewController.view.removeFromSuperview()
                self.currentViewController = transitonVC
                self.transitioning = false
                completion?()
        }
    }
    
    @IBAction func addNewLevel(button : UIButton?){
        if currentViewController !== editViewController && !transitioning {
            transition(editViewController, offset: self.view.bounds.width, completion: { () -> () in
                self.startNewLevel()
            })
        } else {
            startNewLevel()
        }
    }
    
    func cellDidTapEdit(cell: LevelCell) {
        let edit = editViewController as! LevelSelectViewController
        let index = edit.tableView.indexPathForCell(cell)
        let lvl = edit.content[index!.row]
        let levc = self.storyboard?.instantiateViewControllerWithIdentifier("levelEditorVC") as! LevelEditorViewController
        levc.level = lvl
        self.presentViewController(levc, animated: false, completion: nil)
    }
    
    func startNewLevel(){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let lev = self.storyboard?.instantiateViewControllerWithIdentifier("levelEditorVC") as! LevelEditorViewController
            self.presentViewController(lev, animated: true, completion: nil)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func gamePadDidPressButton(button: Button) {
        switch(button){
        case .RightBumper:
            changeToEditViewController(nil)
        case .LeftBumper:
            changeToPlayViewController(nil)
        default:
            currentViewController.gamePadDidPressButton(button)
            break
        }
    }
    
    override func gamePadDidReleaseButton(button: Button) {
        switch(button){

        default:
            currentViewController.gamePadDidReleaseButton(button)
            break
        }
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
