//
//  PlayViewController.swift
//  TestMetal2
//
//  Created by Pål Forsberg on 2016-02-08.
//  Copyright © 2016 Pål Forsberg. All rights reserved.
//

import Foundation


class PlayViewController : GameViewController, UITableViewDelegate {

    override func viewDidLoad() {
        if level == nil {
            level = LevelHandler()
//            level!.importLevel("test.lvl")
        }
//        gameWorld.playLevel(level!)
    }
    
    func pop(){
        let lsvc = self.storyboard?.instantiateViewControllerWithIdentifier("LevelSelect") as! LevelSelectViewController
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(lsvc, animated: false, completion: nil)
        })
    }
    
    func togglePauseGame(){
        if gameWorld.paused {
            //Resume
            self.view.viewWithTag(102)?.removeFromSuperview()
        } else {
            //Stop
            let pauseView = UIView(frame: self.view.bounds)
            pauseView.tag = 102
            
            pauseMenu = PauseTableView(frame: CGRect(x: 30, y: 150, width: 200, height: pauseView.bounds.height - 150))
            pauseMenu!.backgroundColor = UIColor.clearColor()
            pauseMenu!.delegate = self
            
            let courseNameLabel = UILabel(frame: CGRect(x: 30, y: 40, width: pauseView.bounds.width, height: 50))
            courseNameLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 50)
            courseNameLabel.text = gameWorld.level?.name
            
            pauseView.addSubview(courseNameLabel)
            pauseView.addSubview(pauseMenu!)
            self.view.addSubview(pauseView)
        }
        gameWorld.paused = !gameWorld.paused
    }
    
    override func gamePadDidPressPause() {
        togglePauseGame()
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let action_o = PauseAction(rawValue: indexPath.row)
        if let action = action_o {
            switch(action) {
            case .Resume:
                togglePauseGame()
            case .Restart:
                togglePauseGame()
                gameWorld.reset()
            case .Exit:
                pop()
            }
        }
    }
    
}